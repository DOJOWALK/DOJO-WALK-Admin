import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "tool" / "reconcile_lgd_csv.py"
spec = importlib.util.spec_from_file_location("reconcile_lgd_csv", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReconcileLgdCsvTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def csv(self, name, content):
        path = self.root / name
        path.write_text(content, encoding="utf-8")
        return str(path)

    def test_reports_added_removed_and_changed_records(self):
        old = self.csv("old.csv", "LGD Code,Name,Parent\n1,Alpha,10\n2,Beta,10\n")
        new = self.csv("new.csv", "LGD Code,Name,Parent\n1,Alpha New,10\n3,Gamma,11\n")
        report = module.compare_csvs(old, new, "LGD Code", ["Name", "Parent"])
        self.assertEqual(report["added_in_official"], ["3"])
        self.assertEqual(report["removed_from_official"], ["2"])
        self.assertEqual(report["changed_records"][0]["key"], "1")
        self.assertEqual(report["changed_records"][0]["fields"]["Name"]["official"], "Alpha New")
        self.assertFalse(report["passed"])

    def test_trimmed_values_match(self):
        old = self.csv("old.csv", "Code,Name\n1,Alpha \n")
        new = self.csv("new.csv", "Code,Name\n1,Alpha\n")
        report = module.compare_csvs(old, new, "Code", ["Name"])
        self.assertTrue(report["passed"])

    def test_duplicate_keys_fail(self):
        old = self.csv("old.csv", "Code,Name\n1,A\n1,B\n")
        new = self.csv("new.csv", "Code,Name\n1,A\n")
        with self.assertRaisesRegex(ValueError, "duplicate key"):
            module.compare_csvs(old, new, "Code", ["Name"])

    def test_utf8_bom_header_is_supported(self):
        old = self.csv("old.csv", "\\ufeffCode,Name\n001,Alpha\n")
        new = self.csv("new.csv", "Code,Name\n001,Alpha\n")
        self.assertTrue(module.compare_csvs(old, new, "Code", ["Name"])["passed"])

    def test_duplicate_headers_fail(self):
        path = self.csv("duplicate.csv", "Code,Name,Name\n1,A,B\n")
        with self.assertRaisesRegex(ValueError, "duplicate header"):
            module.read_csv(path, "Code", ["Name"])

    def test_blank_header_fails(self):
        path = self.csv("blank_header.csv", "Code,,Name\n1,x,A\n")
        with self.assertRaisesRegex(ValueError, "blank header"):
            module.read_csv(path, "Code", ["Name"])

    def test_extra_unmapped_row_fields_fail(self):
        path = self.csv("extra.csv", "Code,Name\n1,A,UNEXPECTED\n")
        with self.assertRaisesRegex(ValueError, "extra field"):
            module.read_csv(path, "Code", ["Name"])

    def test_empty_file_fails(self):
        path = self.csv("empty.csv", "")
        with self.assertRaisesRegex(ValueError, "no header"):
            module.read_csv(path, "Code", ["Name"])


if __name__ == "__main__":
    unittest.main()
