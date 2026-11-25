import unittest
from contextlib import redirect_stdout
from io import StringIO

from hello import greet, main


class GreetTests(unittest.TestCase):
    def test_default_name(self):
        self.assertEqual(greet(), "Hello, World!")

    def test_custom_name(self):
        self.assertEqual(greet("Ada"), "Hello, Ada!")


class MainTests(unittest.TestCase):
    def test_prints_greeting_for_argument(self):
        buffer = StringIO()
        with redirect_stdout(buffer):
            exit_code = main(["Ada"])
        self.assertEqual(exit_code, 0)
        self.assertEqual(buffer.getvalue(), "Hello, Ada!\n")

    def test_prints_default_greeting_without_arguments(self):
        buffer = StringIO()
        with redirect_stdout(buffer):
            exit_code = main([])
        self.assertEqual(exit_code, 0)
        self.assertEqual(buffer.getvalue(), "Hello, World!\n")


if __name__ == "__main__":
    unittest.main()
