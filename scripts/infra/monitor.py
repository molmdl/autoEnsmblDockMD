#!/usr/bin/env python3
"""
Job log monitor for parsing logs and detecting errors, warnings, and completion status.

Provides LogMonitor class for analyzing GROMACS, gnina, and gmx_MMPBSA log files
to determine job status without manual inspection.
"""

import argparse
import configparser
import os
import re
import sys
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence


class JobStatus(Enum):
    """Job status enumeration.
    
    Attributes:
        RUNNING: Job is currently running (no errors/completion markers).
        COMPLETED: Job finished successfully (completion markers found).
        FAILED: Job encountered errors (error patterns found).
        WARNING: Job has warnings but no errors (warning patterns found).
        UNKNOWN: Cannot determine status (e.g., log file missing).
    """
    RUNNING = 'running'
    COMPLETED = 'completed'
    FAILED = 'failed'
    WARNING = 'warning'
    UNKNOWN = 'unknown'


@dataclass(frozen=True)
class PatternRule:
    """Pattern registry entry with category and severity metadata."""

    kind: str
    pattern: str
    severity: str


class LogMonitor:
    """Monitor job execution via log file parsing.
    
    Analyzes log files for errors, warnings, and completion markers
    to determine job status. Supports GROMACS, gnina, and gmx_MMPBSA logs.
    
    Attributes:
        ERROR_PATTERNS: List of regex patterns for error detection.
        WARNING_PATTERNS: List of regex patterns for warning detection.
        COMPLETION_MARKERS: List of regex patterns for completion detection.
    
    Example:
        >>> monitor = LogMonitor('/path/to/job.log')
        >>> status = monitor.get_status()
        >>> print(status)
        JobStatus.COMPLETED
        
        >>> errors = monitor.check_errors()
        >>> if errors:
        ...     print(f"Found {len(errors)} errors")
    """
    
    DEFAULT_PATTERN_REGISTRY: Sequence[PatternRule] = (
        PatternRule('error', r'\bERROR\b', 'high'),
        PatternRule('error', r'Fatal error', 'high'),
        PatternRule('error', r'Segmentation fault', 'high'),
        PatternRule('error', r'SIGSEGV', 'high'),
        PatternRule('error', r'\bAborted\b', 'high'),
        PatternRule('error', r'CUDA ERROR', 'high'),
        PatternRule('error', r'GROMACS error', 'high'),
        PatternRule('error', r'GPU memory allocation failed', 'high'),
        PatternRule('error', r'Input validation failed', 'high'),
        PatternRule('error', r'Assertion.*failed', 'high'),
        PatternRule('error', r'\bFAILED\b', 'high'),
        PatternRule('error', r'Error:', 'high'),
        PatternRule('error', r'Program terminated', 'high'),
        PatternRule('error', r'Panic', 'high'),
        PatternRule('error', r'Invalid.*parameter', 'medium'),
        PatternRule('error', r'Cannot open file', 'medium'),
        PatternRule('error', r'File not found', 'medium'),
        PatternRule('error', r'Memory allocation failed', 'high'),
        PatternRule('error', r'Out of memory', 'high'),
        PatternRule('error', r'Too many atoms', 'high'),
        PatternRule('error', r'Inconsistent state', 'high'),
        PatternRule('warning', r'\bWARNING\b', 'medium'),
        PatternRule('warning', r'\bWARN\b', 'medium'),
        PatternRule('warning', r'\bNote:', 'low'),
        PatternRule('warning', r'Step.*out of range', 'medium'),
        PatternRule('warning', r'Large.*value', 'medium'),
        PatternRule('warning', r'Maybe you forgot to', 'low'),
        PatternRule('warning', r'This might indicate', 'low'),
        PatternRule('warning', r'POTENTIAL ISSUE', 'medium'),
        PatternRule('warning', r'UNUSUAL', 'medium'),
        PatternRule('warning', r'Could not find', 'medium'),
        PatternRule('warning', r'Guessing', 'low'),
        PatternRule('warning', r'Assuming', 'low'),
        PatternRule('completion', r'GROMACS.*finished', 'info'),
        PatternRule('completion', r'gnina.*finished', 'info'),
        PatternRule('completion', r'Performance:', 'info'),
        PatternRule('completion', r'Final.*energy', 'info'),
        PatternRule('completion', r'Simulation complete', 'info'),
        PatternRule('completion', r'MMPBSA.*complete', 'info'),
        PatternRule('completion', r'Writing output', 'info'),
        PatternRule('completion', r'Complete\.', 'info'),
        PatternRule('completion', r'Done\.', 'info'),
        PatternRule('completion', r'Program finished', 'info'),
        PatternRule('completion', r'Total wall time', 'info'),
        PatternRule('completion', r'Successfully completed', 'info'),
        PatternRule('completion', r'Results written to', 'info'),
        PatternRule('completion', r'Output written to', 'info'),
    )

    DEFAULT_PATTERNS_CONFIG_SECTION = 'monitor_patterns'
    DEFAULT_MAX_MATCHED_LINES = 0

    def __init__(self, log_file: str, config_file: Optional[str] = None):
        """Initialize monitor with log file path.
        
        Args:
            log_file: Path to the log file to monitor.
        
        Raises:
            TypeError: If log_file is not a string.
        """
        if not isinstance(log_file, str):
            raise TypeError(f"log_file must be a string, got {type(log_file)}")
        
        self.log_file = Path(log_file)
        self._pattern_registry = self._load_pattern_registry(config_file)
        self.max_matched_lines = self._load_max_matched_lines(config_file)
        self._compiled_error_patterns = self._compile_patterns('error')
        self._compiled_warning_patterns = self._compile_patterns('warning')
        self._compiled_completion_patterns = self._compile_patterns('completion')

    @staticmethod
    def _sanitize_regex_list(raw_value: str) -> List[str]:
        return [entry.strip() for entry in raw_value.split('||') if entry.strip()]

    def _load_pattern_registry(self, config_file: Optional[str]) -> List[PatternRule]:
        registry = list(self.DEFAULT_PATTERN_REGISTRY)
        if not config_file:
            return registry

        parser = configparser.ConfigParser()
        parser.read(config_file)
        section = self.DEFAULT_PATTERNS_CONFIG_SECTION
        if not parser.has_section(section):
            return registry

        config_section = parser[section]
        mapping = {
            'error_patterns': ('error', 'high'),
            'warning_patterns': ('warning', 'medium'),
            'completion_markers': ('completion', 'info'),
        }

        for key, (kind, severity) in mapping.items():
            value = config_section.get(key, '').strip()
            if not value:
                continue
            parsed = self._sanitize_regex_list(value)
            if parsed:
                registry = [rule for rule in registry if rule.kind != kind]
                registry.extend(PatternRule(kind=kind, pattern=pattern, severity=severity) for pattern in parsed)
        return registry

    def _load_max_matched_lines(self, config_file: Optional[str]) -> int:
        if not config_file:
            return self.DEFAULT_MAX_MATCHED_LINES

        parser = configparser.ConfigParser()
        parser.read(config_file)
        section = self.DEFAULT_PATTERNS_CONFIG_SECTION
        if not parser.has_section(section):
            return self.DEFAULT_MAX_MATCHED_LINES

        raw_limit = parser[section].get('max_matched_lines', str(self.DEFAULT_MAX_MATCHED_LINES)).strip()
        try:
            value = int(raw_limit)
        except ValueError:
            return self.DEFAULT_MAX_MATCHED_LINES
        return max(value, 0)

    def _compile_patterns(self, kind: str) -> List[re.Pattern[str]]:
        return [
            re.compile(rule.pattern, re.IGNORECASE)
            for rule in self._pattern_registry
            if rule.kind == kind
        ]

    def _limit_matches(self, matches: List[str]) -> List[str]:
        if self.max_matched_lines <= 0:
            return matches
        return matches[: self.max_matched_lines]
    
    def _file_exists(self) -> bool:
        """Check if log file exists.
        
        Returns:
            True if file exists, False otherwise.
        """
        return self.log_file.exists()
    
    def _read_lines(self) -> List[str]:
        """Read all lines from log file.
        
        Returns:
            List of lines from the file, or empty list if file doesn't exist.
        """
        if not self._file_exists():
            return []
        
        try:
            with open(self.log_file, 'r', encoding='utf-8', errors='replace') as f:
                return f.readlines()
        except IOError:
            return []
    
    def check_errors(self) -> List[str]:
        """Scan log file for error patterns.
        
        Returns:
            List of lines containing error patterns.
        
        Example:
            >>> monitor = LogMonitor('crash.log')
            >>> errors = monitor.check_errors()
            >>> print(f"Found {len(errors)} error lines")
        """
        if not self._file_exists():
            return []
        
        errors = []
        lines = self._read_lines()
        
        for line in lines:
            for pattern in self._compiled_error_patterns:
                if pattern.search(line):
                    errors.append(line.rstrip('\n'))
                    break  # Don't count same line multiple times
        
        return self._limit_matches(errors)
    
    def check_warnings(self) -> List[str]:
        """Scan log file for warning patterns.
        
        Returns:
            List of lines containing warning patterns.
        
        Example:
            >>> monitor = LogMonitor('job.log')
            >>> warnings = monitor.check_warnings()
            >>> for w in warnings:
            ...     print(w)
        """
        if not self._file_exists():
            return []
        
        warnings = []
        lines = self._read_lines()
        
        for line in lines:
            for pattern in self._compiled_warning_patterns:
                if pattern.search(line):
                    warnings.append(line.rstrip('\n'))
                    break  # Don't count same line multiple times
        
        return self._limit_matches(warnings)
    
    def check_completion(self) -> bool:
        """Check if job completed successfully.
        
        Returns:
            True if completion markers found in log file.
        
        Example:
            >>> monitor = LogMonitor('job.log')
            >>> if monitor.check_completion():
            ...     print("Job finished successfully")
        """
        if not self._file_exists():
            return False
        
        lines = self._read_lines()
        
        for line in lines:
            for pattern in self._compiled_completion_patterns:
                if pattern.search(line):
                    return True
        
        return False
    
    def get_status(self) -> JobStatus:
        """Determine overall job status from log analysis.
        
        Status priority:
        1. FAILED - if error patterns found
        2. COMPLETED - if completion markers found (and no errors)
        3. WARNING - if warning patterns found (and no errors/completion)
        4. RUNNING - if file exists but no markers
        5. UNKNOWN - if file doesn't exist
        
        Returns:
            JobStatus enum value.
        
        Example:
            >>> monitor = LogMonitor('job.log')
            >>> status = monitor.get_status()
            >>> print(f"Job status: {status.value}")
        """
        # Check if file exists
        if not self._file_exists():
            return JobStatus.UNKNOWN
        
        # Check for errors first (highest priority)
        errors = self.check_errors()
        if errors:
            return JobStatus.FAILED
        
        # Check for completion markers
        if self.check_completion():
            return JobStatus.COMPLETED
        
        # Check for warnings
        warnings = self.check_warnings()
        if warnings:
            return JobStatus.WARNING
        
        # File exists but no markers - likely still running
        return JobStatus.RUNNING
    
    def get_summary(self) -> Dict[str, Any]:
        """Get comprehensive log analysis summary.
        
        Returns:
            Dictionary containing:
            - status: Job status string
            - log_file: Path to log file
            - errors: List of error lines
            - warnings: List of warning lines
            - completed: Whether job completed
            - error_count: Number of errors
            - warning_count: Number of warnings
            - file_exists: Whether log file exists
            - file_size: File size in bytes (0 if doesn't exist)
        
        Example:
            >>> monitor = LogMonitor('job.log')
            >>> summary = monitor.get_summary()
            >>> print(json.dumps(summary, indent=2))
        """
        errors = self.check_errors()
        warnings = self.check_warnings()
        completed = self.check_completion()
        status = self.get_status()
        
        file_size = 0
        if self._file_exists():
            try:
                file_size = self.log_file.stat().st_size
            except OSError:
                pass
        
        return {
            'status': status.value,
            'log_file': str(self.log_file),
            'errors': errors,
            'warnings': warnings,
            'completed': completed,
            'error_count': len(errors),
            'warning_count': len(warnings),
            'file_exists': self._file_exists(),
            'file_size': file_size,
        }
    
    def tail(self, n: int = 50) -> str:
        """Get last n lines of log file.
        
        Efficiently reads only the end of the file without loading
        entire file into memory.
        
        Args:
            n: Number of lines to return (default: 50).
        
        Returns:
            String containing last n lines of log file.
            Empty string if file doesn't exist.
        
        Example:
            >>> monitor = LogMonitor('job.log')
            >>> print(monitor.tail(10))
        """
        if not self._file_exists():
            return ''
        
        try:
            # Read all lines for simplicity (handles edge cases)
            # For very large files, could use seek from end
            lines = self._read_lines()
            last_lines = lines[-n:] if len(lines) > n else lines
            return ''.join(last_lines)
        except IOError:
            return ''
    
    def grep(self, pattern: str) -> List[str]:
        """Search for pattern in log file.
        
        Args:
            pattern: Regex pattern to search for.
        
        Returns:
            List of lines matching the pattern.
        
        Example:
            >>> monitor = LogMonitor('job.log')
            >>> matches = monitor.grep(r'energy')
            >>> for match in matches:
            ...     print(match)
        """
        if not self._file_exists():
            return []
        
        try:
            compiled = re.compile(pattern, re.IGNORECASE)
        except re.error as e:
            raise ValueError(f"Invalid regex pattern: {e}")
        
        matches = []
        lines = self._read_lines()
        
        for line in lines:
            if compiled.search(line):
                matches.append(line.rstrip('\n'))
        
        return matches


def main():
    """CLI interface for log monitor module."""
    parser = argparse.ArgumentParser(
        description='Job log monitor for GROMACS/gnina/gmx_MMPBSA logs',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Check job status
  python -m scripts.infra.monitor status --log /path/to/job.log

  # List all errors
  python -m scripts.infra.monitor errors --log /path/to/job.log

  # List all warnings
  python -m scripts.infra.monitor warnings --log /path/to/job.log

  # Get full summary (JSON)
  python -m scripts.infra.monitor summary --log /path/to/job.log

  # Tail last N lines
  python -m scripts.infra.monitor tail --log /path/to/job.log --lines 20

  # Grep for pattern
  python -m scripts.infra.monitor grep --log /path/to/job.log --pattern "energy"
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # status subcommand
    status_parser = subparsers.add_parser('status', help='Get job status')
    status_parser.add_argument('--log', required=True, help='Path to log file')
    status_parser.add_argument('--config', default=None, help='Optional config for monitor patterns')
    
    # errors subcommand
    errors_parser = subparsers.add_parser('errors', help='List error lines')
    errors_parser.add_argument('--log', required=True, help='Path to log file')
    errors_parser.add_argument('--config', default=None, help='Optional config for monitor patterns')
    
    # warnings subcommand
    warnings_parser = subparsers.add_parser('warnings', help='List warning lines')
    warnings_parser.add_argument('--log', required=True, help='Path to log file')
    warnings_parser.add_argument('--config', default=None, help='Optional config for monitor patterns')
    
    # summary subcommand
    summary_parser = subparsers.add_parser('summary', help='Get full summary')
    summary_parser.add_argument('--log', required=True, help='Path to log file')
    summary_parser.add_argument('--config', default=None, help='Optional config for monitor patterns')
    
    # tail subcommand
    tail_parser = subparsers.add_parser('tail', help='Get last N lines')
    tail_parser.add_argument('--log', required=True, help='Path to log file')
    tail_parser.add_argument('--lines', type=int, default=50, help='Number of lines (default: 50)')
    tail_parser.add_argument('--config', default=None, help='Optional config for monitor patterns')
    
    # grep subcommand
    grep_parser = subparsers.add_parser('grep', help='Search for pattern')
    grep_parser.add_argument('--log', required=True, help='Path to log file')
    grep_parser.add_argument('--pattern', required=True, help='Regex pattern to search')
    grep_parser.add_argument('--config', default=None, help='Optional config for monitor patterns')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        monitor = LogMonitor(args.log, config_file=args.config)
        
        if args.command == 'status':
            status = monitor.get_status()
            print(f"Status: {status.value}")
            print(f"Log file: {args.log}")
            
        elif args.command == 'errors':
            errors = monitor.check_errors()
            if errors:
                print(f"Found {len(errors)} error(s):")
                for err in errors:
                    print(f"  {err}")
            else:
                print("No errors found")
        
        elif args.command == 'warnings':
            warnings = monitor.check_warnings()
            if warnings:
                print(f"Found {len(warnings)} warning(s):")
                for warn in warnings:
                    print(f"  {warn}")
            else:
                print("No warnings found")
        
        elif args.command == 'summary':
            import json
            summary = monitor.get_summary()
            print(json.dumps(summary, indent=2))
        
        elif args.command == 'tail':
            output = monitor.tail(args.lines)
            if output:
                print(output, end='')
            else:
                print("(empty or file not found)")
        
        elif args.command == 'grep':
            matches = monitor.grep(args.pattern)
            if matches:
                print(f"Found {len(matches)} match(es):")
                for match in matches:
                    print(f"  {match}")
            else:
                print("No matches found")
    
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
