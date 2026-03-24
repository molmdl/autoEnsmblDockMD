#!/usr/bin/env python3
"""
INI configuration file manager for pipeline settings.

Provides ConfigManager class for reading INI configuration files with
type conversion, fallback handling, and environment detection.
"""

import argparse
import configparser
import os
import sys
from pathlib import Path
from typing import Any, Dict, Optional


class ConfigManager:
    """INI configuration file manager for pipeline settings.
    
    Supports DEFAULT section inheritance, type conversion with fallbacks,
    and environment detection for execution backend.
    
    Attributes:
        config_path: Path to the INI configuration file.
        parser: ConfigParser instance for reading the file.
    
    Example:
        >>> config = ConfigManager('/path/to/config.ini')
        >>> value = config.get('section', 'key', 'default_value')
        >>> num = config.getint('section', 'number', 0)
    """
    
    def __init__(self, config_path: str):
        """Initialize configuration manager and load from file.
        
        Args:
            config_path: Path to the INI configuration file.
        
        Raises:
            FileNotFoundError: If config file does not exist.
            configparser.Error: If config file is malformed.
        """
        self.config_path = Path(config_path)
        self.parser = configparser.ConfigParser()
        
        if not self.config_path.exists():
            raise FileNotFoundError(f"Configuration file not found: {config_path}")
        
        self.parser.read(self.config_path)
    
    def get(self, section: str, key: str, fallback: Any = None) -> Optional[str]:
        """Get string value with fallback.
        
        Args:
            section: Section name in INI file.
            key: Key name within the section.
            fallback: Default value if key not found.
        
        Returns:
            String value from config, or fallback if not found.
            Returns None if missing and no fallback provided.
        """
        try:
            return self.parser.get(section, key)
        except (configparser.NoSectionError, configparser.NoOptionError):
            return fallback
    
    def getint(self, section: str, key: str, fallback: int = None) -> Optional[int]:
        """Get integer value with fallback.
        
        Args:
            section: Section name in INI file.
            key: Key name within the section.
            fallback: Default value if key not found or conversion fails.
        
        Returns:
            Integer value from config, or fallback if not found or invalid.
            Returns None if missing and no fallback provided.
        """
        try:
            return self.parser.getint(section, key)
        except (configparser.NoSectionError, configparser.NoOptionError):
            return fallback
        except (ValueError, TypeError):
            return fallback
    
    def getfloat(self, section: str, key: str, fallback: float = None) -> Optional[float]:
        """Get float value with fallback.
        
        Args:
            section: Section name in INI file.
            key: Key name within the section.
            fallback: Default value if key not found or conversion fails.
        
        Returns:
            Float value from config, or fallback if not found or invalid.
            Returns None if missing and no fallback provided.
        """
        try:
            return self.parser.getfloat(section, key)
        except (configparser.NoSectionError, configparser.NoOptionError):
            return fallback
        except (ValueError, TypeError):
            return fallback
    
    def getboolean(self, section: str, key: str, fallback: bool = None) -> Optional[bool]:
        """Get boolean value with fallback.
        
        Args:
            section: Section name in INI file.
            key: Key name within the section.
            fallback: Default value if key not found or conversion fails.
        
        Returns:
            Boolean value from config, or fallback if not found or invalid.
            Returns None if missing and no fallback provided.
        
        Note:
            Accepts standard boolean values: yes/no, true/false, 1/0
        """
        try:
            return self.parser.getboolean(section, key)
        except (configparser.NoSectionError, configparser.NoOptionError):
            return fallback
        except (ValueError, TypeError):
            return fallback
    
    def get_section(self, section: str) -> Dict[str, str]:
        """Get all key-value pairs from a section.
        
        Args:
            section: Section name in INI file.
        
        Returns:
            Dictionary of all key-value pairs in the section.
            Returns empty dict if section does not exist.
        """
        try:
            return dict(self.parser.items(section))
        except configparser.NoSectionError:
            return {}
    
    def get_execution_backend(self) -> str:
        """Get execution backend with auto-detection support.
        
        Reads execution.backend from config file. If value is 'auto',
        attempts to detect available execution environment.
        
        Returns:
            Backend name ('slurm', 'local', etc.)
        
        Environment detection order:
            1. Check for SLURM environment variables
            2. Fall back to 'local' execution
        """
        backend = self.get('execution', 'backend', 'auto')
        
        if backend == 'auto':
            # Auto-detect execution environment
            if 'SLURM_JOB_ID' in os.environ:
                return 'slurm'
            else:
                return 'local'
        
        return backend
    
    def __repr__(self) -> str:
        """String representation of ConfigManager."""
        return f"ConfigManager(config_path='{self.config_path}')"


def main():
    """CLI interface for ConfigManager."""
    parser = argparse.ArgumentParser(
        description='Read values from INI configuration files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Get a string value
  python -m scripts.infra.config --config config.ini --section database --key host

  # Get an integer value
  python -m scripts.infra.config --config config.ini --section limits --key max_retries --type int

  # Get all values in a section
  python -m scripts.infra.config --config config.ini --section database --all
        """
    )
    
    parser.add_argument('--config', required=True, help='Path to INI configuration file')
    parser.add_argument('--section', required=True, help='Section name')
    parser.add_argument('--key', help='Key name (optional if --all is used)')
    parser.add_argument('--type', choices=['str', 'int', 'float', 'bool'],
                        default='str', help='Value type (default: str)')
    parser.add_argument('--all', action='store_true',
                        help='Get all keys in section')
    parser.add_argument('--fallback', help='Fallback value if key not found')
    
    args = parser.parse_args()
    
    try:
        config = ConfigManager(args.config)
        
        if args.all:
            # Get all values in section
            section_data = config.get_section(args.section)
            if not section_data:
                print(f"Section '{args.section}' not found or empty", file=sys.stderr)
                sys.exit(1)
            
            for key, value in section_data.items():
                print(f"{key} = {value}")
        else:
            # Get single value
            if not args.key:
                print("Error: --key is required when not using --all", file=sys.stderr)
                sys.exit(1)
            
            type_map = {
                'str': config.get,
                'int': config.getint,
                'float': config.getfloat,
                'bool': config.getboolean
            }
            
            fallback = args.fallback
            if args.type == 'int' and fallback is not None:
                fallback = int(fallback)
            elif args.type == 'float' and fallback is not None:
                fallback = float(fallback)
            elif args.type == 'bool' and fallback is not None:
                fallback = fallback.lower() in ('true', 'yes', '1')
            
            value = type_map[args.type](args.section, args.key, fallback)
            
            if value is None:
                print(f"Key '{args.key}' not found in section '{args.section}'",
                      file=sys.stderr)
                sys.exit(1)
            
            print(value)
    
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
