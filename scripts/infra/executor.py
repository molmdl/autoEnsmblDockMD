#!/usr/bin/env python3
"""
Execution backend manager for local and Slurm job execution.

Provides automatic environment detection and unified interface for running
commands locally or submitting jobs to Slurm scheduler.
"""

import argparse
import os
import shlex
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple


def detect_execution_backend() -> str:
    """Detect execution environment (local vs slurm).
    
    Checks for SLURM environment variables to determine if running in
    a Slurm allocation or batch job.
    
    Returns:
        'slurm' if any SLURM_* environment variable is set, else 'local'.
    
    Environment variables checked:
        - SLURM_JOB_ID: Set in batch jobs
        - SLURM_TMPDIR: Set in batch jobs on some clusters
        - SLURM_NODELIST: Set in batch jobs
    """
    slurm_indicators = ['SLURM_JOB_ID', 'SLURM_TMPDIR', 'SLURM_NODELIST']
    
    for var in slurm_indicators:
        if var in os.environ and os.environ[var]:
            return 'slurm'
    
    return 'local'


class LocalExecutor:
    """Local command execution.
    
    Provides synchronous command execution with output capture,
    timeout support, and environment variable override.
    
    Example:
        >>> executor = LocalExecutor()
        >>> ret, out, err = executor.run_command(['echo', 'hello'])
        >>> print(out.strip())
        'hello'
    """
    
    def __init__(self):
        """Initialize local executor."""
        pass
    
    def run_command(self, command: List[str], cwd: str = None,
                    env: Dict[str, str] = None, timeout: int = None) -> Tuple[int, str, str]:
        """Run command locally and capture output.
        
        Args:
            command: Command and arguments as list.
            cwd: Working directory for command execution.
            env: Environment variables to add/override (merged with current env).
            timeout: Timeout in seconds. Raises TimeoutExpired if exceeded.
        
        Returns:
            Tuple of (returncode, stdout, stderr).
        
        Raises:
            subprocess.TimeoutExpired: If timeout is exceeded.
            FileNotFoundError: If command executable not found.
        
        Example:
            >>> executor.run_command(['ls', '-la'], cwd='/tmp')
            (0, 'total 16\\ndrwxrwxrwt...', '')
        """
        # Merge environment variables
        run_env = os.environ.copy()
        if env:
            run_env.update(env)
        
        try:
            result = subprocess.run(
                command,
                cwd=cwd,
                env=run_env,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return (result.returncode, result.stdout, result.stderr)
        except subprocess.TimeoutExpired as e:
            # Re-raise with context
            raise
        except FileNotFoundError as e:
            raise FileNotFoundError(f"Command not found: {command[0]}") from e
    
    def run_script(self, script_path: str, args: List[str] = None, **kwargs) -> Tuple[int, str, str]:
        """Run a script file.
        
        Args:
            script_path: Path to script file.
            args: Additional arguments for the script.
            **kwargs: Additional arguments passed to run_command.
        
        Returns:
            Tuple of (returncode, stdout, stderr).
        
        Example:
            >>> executor.run_script('./run_analysis.sh', ['--input', 'data.txt'])
            (0, 'Analysis complete...', '')
        """
        script = Path(script_path)
        
        if not script.exists():
            raise FileNotFoundError(f"Script not found: {script_path}")
        
        command = [str(script)]
        if args:
            command.extend(args)
        
        return self.run_command(command, **kwargs)


class SlurmExecutor:
    """Slurm job submission and management.
    
    Provides interface for submitting, monitoring, and canceling Slurm jobs.
    Uses sbatch/squeue/scancel commands under the hood.
    
    Attributes:
        account: Slurm account for job charging (optional).
        default_time: Default time limit (format: HH:MM:SS).
        default_cpus: Default number of CPUs per task.
        default_mem: Default memory per node.
    
    Example:
        >>> executor = SlurmExecutor(account='myproject')
        >>> job_id = executor.submit_job('run_simulation.sh', job_name='sim1')
        >>> status, output = executor.wait_for_job(job_id)
    """
    
    # Terminal job states
    TERMINAL_STATES = {
        'COMPLETED',
        'FAILED',
        'CANCELLED',
        'TIMEOUT',
        'NODE_FAIL',
        'OUT_OF_MEMORY'
    }

    FAILURE_STATES = {
        'FAILED',
        'CANCELLED',
        'TIMEOUT',
        'NODE_FAIL',
        'OUT_OF_MEMORY',
        'BOOT_FAIL',
        'PREEMPTED',
        'DEADLINE',
        'REVOKED',
    }
    
    def __init__(self, account: str = None, default_time: str = '02:00:00',
                 default_cpus: int = 1, default_mem: str = '4G'):
        """Initialize Slurm executor with defaults.
        
        Args:
            account: Slurm account for job charging. If None, omitted from command.
            default_time: Default time limit (format: HH:MM:SS).
            default_cpus: Default number of CPUs per task.
            default_mem: Default memory per node (e.g., '4G', '4096M').
        """
        self.account = account
        self.default_time = default_time
        self.default_cpus = default_cpus
        self.default_mem = default_mem
        
        # Check if Slurm commands are available
        self._check_slurm_available()
    
    def _check_slurm_available(self) -> None:
        """Check if Slurm commands (sbatch, squeue, scancel) are available.
        
        Raises:
            RuntimeError: If sbatch command is not found.
        """
        try:
            subprocess.run(
                ['which', 'sbatch'],
                capture_output=True,
                check=True
            )
        except subprocess.CalledProcessError:
            raise RuntimeError(
                "Slurm commands not found. Ensure Slurm is installed and in PATH."
            )
    
    def submit_job(self, script_path: str, job_name: str = 'autoEnsmbl',
                   time: str = None, cpus: int = None, mem: str = None,
                   output: str = None, error: str = None,
                   extra_args: List[str] = None) -> str:
        """Submit job to Slurm scheduler.
        
        Args:
            script_path: Path to job script.
            job_name: Name for the job (shown in squeue).
            time: Time limit (format: HH:MM:SS). Uses default if None.
            cpus: Number of CPUs per task. Uses default if None.
            mem: Memory per node. Uses default if None.
            output: Path for stdout file. If None, uses Slurm default.
            error: Path for stderr file. If None, uses Slurm default.
            extra_args: Additional arguments to pass to sbatch.
        
        Returns:
            Job ID as string.
        
        Raises:
            RuntimeError: If job submission fails.
            FileNotFoundError: If script file not found.
        
        Example:
            >>> executor.submit_job('run.sh', job_name='analysis',
            ...                     time='04:00:00', cpus=8, mem='16G')
            '12345'
        """
        script = Path(script_path)
        
        if not script.exists():
            raise FileNotFoundError(f"Script not found: {script_path}")
        
        # Build sbatch command
        cmd = ['sbatch']
        
        cmd.extend(['--job-name', job_name])
        cmd.extend(['--time', time or self.default_time])
        cmd.extend(['--cpus-per-task', str(cpus or self.default_cpus)])
        cmd.extend(['--mem', mem or self.default_mem])
        
        if self.account:
            cmd.extend(['--account', self.account])
        
        if output:
            cmd.extend(['--output', output])
        
        if error:
            cmd.extend(['--error', error])
        
        if extra_args:
            cmd.extend(extra_args)
        
        cmd.append(str(script))
        
        # Submit job
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True
            )
            
            # Parse job ID from output: "Submitted batch job 12345"
            output = result.stdout.strip()
            if 'Submitted batch job' in output:
                job_id = output.split()[-1]
                return job_id
            else:
                raise RuntimeError(f"Unexpected sbatch output: {output}")
                
        except subprocess.CalledProcessError as e:
            raise RuntimeError(
                f"Failed to submit job: {e.stderr.strip() if e.stderr else str(e)}"
            ) from e
    
    def get_job_status(self, job_id: str) -> str:
        """Get job status from Slurm queue.
        
        Args:
            job_id: Slurm job ID.
        
        Returns:
            Job status: PENDING, RUNNING, COMPLETED, FAILED, CANCELLED,
                       TIMEOUT, NODE_FAIL, OUT_OF_MEMORY, or UNKNOWN.
        
        Example:
            >>> executor.get_job_status('12345')
            'RUNNING'
        """
        try:
            result = subprocess.run(
                ['squeue', '-j', job_id, '-h', '-o', '%T'],
                capture_output=True,
                text=True,
                check=True
            )
            
            status = result.stdout.strip()
            
            if status:
                return status
            else:
                # Job not in queue - could be completed or failed
                # Check for output file existence later in wait_for_job
                return 'UNKNOWN'
                
        except subprocess.CalledProcessError as e:
            # Job not found or squeue failed
            return 'UNKNOWN'

    def get_job_terminal_state(self, job_id: str) -> str:
        """Resolve final Slurm terminal state using sacct.

        Returns:
            Canonical terminal state (e.g., COMPLETED/FAILED/...) or UNKNOWN.
        """
        try:
            result = subprocess.run(
                ['sacct', '-n', '-P', '-j', job_id, '-o', 'JobIDRaw,State'],
                capture_output=True,
                text=True,
                check=True
            )
        except subprocess.CalledProcessError:
            return 'UNKNOWN'

        terminal = 'UNKNOWN'
        for raw in result.stdout.splitlines():
            line = raw.strip()
            if not line:
                continue
            parts = line.split('|')
            if len(parts) < 2:
                continue
            row_job_id = parts[0].strip()
            row_state = parts[1].strip().upper()
            # Keep only root job record, ignore step records (e.g. 12345.batch)
            if row_job_id != str(job_id):
                continue
            state_base = row_state.split()[0].split('+')[0]
            terminal = state_base or 'UNKNOWN'
            break

        return terminal
    
    def wait_for_job(self, job_id: str, poll_interval: int = 30,
                     timeout: int = None) -> Tuple[str, str]:
        """Wait for job completion and return final status.
        
        Polls squeue at regular intervals until job reaches terminal state.
        
        Args:
            job_id: Slurm job ID.
            poll_interval: Seconds between status checks (default: 30).
            timeout: Maximum wait time in seconds. None for no limit.
        
        Returns:
            Tuple of (final_status, output_file_path).
            - final_status: One of the terminal states or 'UNKNOWN'.
            - output_file_path: Path to job output file if detectable.
        
        Raises:
            TimeoutError: If timeout is exceeded.
        
        Example:
            >>> status, output = executor.wait_for_job('12345', poll_interval=60)
            >>> print(f"Job finished with status: {status}")
        """
        start_time = time.time()
        output_file = None
        
        # Try to detect output file path from job ID
        # Slurm default: slurm-{job_id}.out
        default_output = f"slurm-{job_id}.out"
        if Path(default_output).exists():
            output_file = default_output
        
        while True:
            # Check timeout
            if timeout is not None:
                elapsed = time.time() - start_time
                if elapsed > timeout:
                    raise TimeoutError(
                        f"Timeout waiting for job {job_id} after {timeout}s"
                    )
            
            # Get job status
            status = self.get_job_status(job_id)
            
            # Check if terminal state
            if status in self.TERMINAL_STATES:
                return (status, output_file)
            
            # Check if job is no longer visible in squeue
            if status == 'UNKNOWN':
                terminal_state = self.get_job_terminal_state(job_id)
                if terminal_state == 'COMPLETED':
                    return ('COMPLETED', output_file)
                if terminal_state in self.FAILURE_STATES or terminal_state in self.TERMINAL_STATES:
                    return (terminal_state, output_file)

                # Do not assume success when scheduler state is indeterminate.
                return ('FAILED', output_file)
            
            # Wait before next check
            time.sleep(poll_interval)
    
    def cancel_job(self, job_id: str) -> bool:
        """Cancel a running or pending job.
        
        Args:
            job_id: Slurm job ID.
        
        Returns:
            True if cancellation successful, False otherwise.
        
        Example:
            >>> executor.cancel_job('12345')
            True
        """
        try:
            result = subprocess.run(
                ['scancel', job_id],
                capture_output=True,
                text=True,
                check=True
            )
            return True
        except subprocess.CalledProcessError:
            return False
    
    def get_queue_info(self, user: str = None) -> List[Dict[str, str]]:
        """Get queue information for user.
        
        Args:
            user: Username to query. If None, uses current user ($USER).
        
        Returns:
            List of dictionaries with job information:
            - job_id: Job ID
            - name: Job name
            - status: Job status
            - time: Elapsed time
            - nodes: Number of nodes
        
        Example:
            >>> jobs = executor.get_queue_info()
            >>> for job in jobs:
            ...     print(f"{job['job_id']}: {job['name']} - {job['status']}")
        """
        if user is None:
            user = os.environ.get('USER', '')
        
        try:
            result = subprocess.run(
                ['squeue', '-u', user, '-h', '-o', '%i|%j|%T|%M|%D'],
                capture_output=True,
                text=True,
                check=True
            )
            
            jobs = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    parts = line.split('|')
                    if len(parts) >= 5:
                        jobs.append({
                            'job_id': parts[0],
                            'name': parts[1],
                            'status': parts[2],
                            'time': parts[3],
                            'nodes': parts[4]
                        })
            
            return jobs
            
        except subprocess.CalledProcessError:
            return []


def main():
    """CLI interface for executor module."""
    parser = argparse.ArgumentParser(
        description='Execution backend manager for local and Slurm execution',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Detect execution environment
  python -m scripts.infra.executor detect

  # Run command locally
  python -m scripts.infra.executor local --cmd "echo hello"

  # Submit Slurm job
  python -m scripts.infra.executor slurm --script run.sh --name test --time 01:00:00

  # Check job status
  python -m scripts.infra.executor status --job-id 12345

  # Get queue info
  python -m scripts.infra.executor queue
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # detect subcommand
    detect_parser = subparsers.add_parser('detect', help='Detect execution backend')
    
    # local subcommand
    local_parser = subparsers.add_parser('local', help='Run command locally')
    local_parser.add_argument('--cmd', required=True, help='Command to run')
    local_parser.add_argument('--cwd', help='Working directory')
    local_parser.add_argument('--timeout', type=int, help='Timeout in seconds')
    
    # slurm subcommand
    slurm_parser = subparsers.add_parser('slurm', help='Submit Slurm job')
    slurm_parser.add_argument('--script', required=True, help='Path to job script')
    slurm_parser.add_argument('--name', default='autoEnsmbl', help='Job name')
    slurm_parser.add_argument('--time', default='02:00:00', help='Time limit (HH:MM:SS)')
    slurm_parser.add_argument('--cpus', type=int, default=1, help='CPUs per task')
    slurm_parser.add_argument('--mem', default='4G', help='Memory per node')
    slurm_parser.add_argument('--account', help='Slurm account')
    slurm_parser.add_argument('--output', help='Output file path')
    slurm_parser.add_argument('--error', help='Error file path')
    slurm_parser.add_argument('--wait', action='store_true', help='Wait for completion')
    slurm_parser.add_argument('--poll-interval', type=int, default=30,
                             help='Poll interval in seconds when waiting')
    
    # status subcommand
    status_parser = subparsers.add_parser('status', help='Get job status')
    status_parser.add_argument('--job-id', required=True, help='Job ID')
    
    # cancel subcommand
    cancel_parser = subparsers.add_parser('cancel', help='Cancel job')
    cancel_parser.add_argument('--job-id', required=True, help='Job ID')
    
    # queue subcommand
    queue_parser = subparsers.add_parser('queue', help='Get queue information')
    queue_parser.add_argument('--user', help='Username (default: current user)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        if args.command == 'detect':
            backend = detect_execution_backend()
            print(f"Detected backend: {backend}")
        
        elif args.command == 'local':
            executor = LocalExecutor()
            # Parse command string into list
            cmd = shlex.split(args.cmd)
            
            ret, out, err = executor.run_command(
                cmd,
                cwd=args.cwd,
                timeout=args.timeout
            )
            
            print(f"Return code: {ret}")
            if out:
                print(f"STDOUT:\n{out}")
            if err:
                print(f"STDERR:\n{err}", file=sys.stderr)
            
            sys.exit(ret)
        
        elif args.command == 'slurm':
            slurm_executor = SlurmExecutor(account=args.account)
            job_id = slurm_executor.submit_job(
                args.script,
                job_name=args.name,
                time=args.time,
                cpus=args.cpus,
                mem=args.mem,
                output=args.output,
                error=args.error
            )
            
            print(f"Submitted job: {job_id}")
            
            if args.wait:
                print(f"Waiting for job {job_id} to complete...")
                status, output_file = slurm_executor.wait_for_job(
                    job_id,
                    poll_interval=args.poll_interval
                )
                print(f"Job finished with status: {status}")
                if output_file:
                    print(f"Output file: {output_file}")
        
        elif args.command == 'status':
            slurm_executor = SlurmExecutor()
            status = slurm_executor.get_job_status(args.job_id)
            print(f"Job {args.job_id} status: {status}")
        
        elif args.command == 'cancel':
            slurm_executor = SlurmExecutor()
            success = slurm_executor.cancel_job(args.job_id)
            if success:
                print(f"Job {args.job_id} cancelled")
            else:
                print(f"Failed to cancel job {args.job_id}", file=sys.stderr)
                sys.exit(1)
        
        elif args.command == 'queue':
            slurm_executor = SlurmExecutor()
            jobs = slurm_executor.get_queue_info(user=args.user)
            
            if not jobs:
                print("No jobs in queue")
            else:
                print(f"{'Job ID':<10} {'Name':<20} {'Status':<12} {'Time':<10} {'Nodes':<10}")
                print("-" * 62)
                for job in jobs:
                    print(f"{job['job_id']:<10} {job['name']:<20} {job['status']:<12} "
                          f"{job['time']:<10} {job['nodes']:<10}")
    
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except TimeoutError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nInterrupted", file=sys.stderr)
        sys.exit(130)


if __name__ == '__main__':
    main()
