#!/usr/bin/env python3
"""
Extract ligand topology from GROMACS .top file to .itp file.

Extracts content from [ moleculetype ] section to before water topology comment.
"""

import argparse
import re
import sys
from pathlib import Path


def extract_ligand_topology(input_file: str, output_file: str = None, verbose: bool = False) -> str:
    """
    Extract ligand topology from GROMACS topology file.
    
    Parameters
    ----------
    input_file : str
        Path to input .top file
    output_file : str, optional
        Path to output .itp file. If None, uses same prefix as input.
    verbose : bool
        Print progress messages
    
    Returns
    -------
    str
        Path to output file
    """
    input_path = Path(input_file).resolve()
    
    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")
    
    if output_file is None:
        output_path = input_path.with_suffix('.itp')
    else:
        output_path = Path(output_file).resolve()
    
    with open(input_path, 'r') as f:
        lines = f.readlines()
    
    start_idx = None
    end_idx = None
    
    water_patterns = [
        r';\s*Include water topology',
        r';\s*water topology',
        r';\s*Water',
        r'#include.*water.*\.itp',
        r'#include.*tip3p.*\.itp',
        r'#include.*spc.*\.itp',
        r'\[ system \]',
    ]
    
    for i, line in enumerate(lines):
        if start_idx is None and line.strip().startswith('[ moleculetype ]'):
            start_idx = i
            if verbose:
                print(f"Found [ moleculetype ] at line {i + 1}")
            continue
        
        if start_idx is not None and end_idx is None:
            for pattern in water_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    end_idx = i
                    if verbose:
                        print(f"Found water topology marker at line {i + 1}: {line.strip()}")
                    break
    
    if start_idx is None:
        raise ValueError(f"No [ moleculetype ] section found in {input_path}")
    
    if end_idx is None:
        end_idx = len(lines)
        if verbose:
            print("No water topology marker found, extracting to end of file")
    
    extracted_lines = lines[start_idx:end_idx]
    
    while extracted_lines and extracted_lines[-1].strip() == '':
        extracted_lines.pop()
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w') as f:
        f.writelines(extracted_lines)
    
    if verbose:
        print(f"Extracted {len(extracted_lines)} lines")
        print(f"Output written to: {output_path}")
    
    return str(output_path)


def main():
    parser = argparse.ArgumentParser(
        description='Extract ligand topology from GROMACS .top file to .itp file'
    )
    parser.add_argument(
        'input_file',
        help='Input GROMACS topology file (.top)'
    )
    parser.add_argument(
        '-o', '--output',
        help='Output .itp file (default: same prefix as input)'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Print progress messages'
    )
    
    args = parser.parse_args()
    
    try:
        output_path = extract_ligand_topology(args.input_file, args.output, args.verbose)
        print(output_path)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
