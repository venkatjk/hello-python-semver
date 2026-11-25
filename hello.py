"""A small hello-world application."""

import sys


def greet(name: str = "World") -> str:
    """Return a greeting for the givens name."""
    return f"Hello, {name}!"


def main(argv: list[str] | None = None) -> int:
    """Print a greeting. Uses the first argument as the name, if one is given."""
    args = sys.argv[1:] if argv is None else argv
    name = args[0] if args else "World"
    print(greet(name))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
