"""Guard the UI driver's activity boundary and observed tap coordinates."""
import unittest
from android_picker_driver import center, picker_action


def xml(package, text="SAVE", resource="android:id/button1", bounds="[10,20][110,80]", enabled="true"):
    return f'<hierarchy><node package="{package}" text="{text}" resource-id="{resource}" bounds="{bounds}" enabled="{enabled}"/></hierarchy>'


class PickerDriverTest(unittest.TestCase):
    def test_only_real_picker_controls_are_tapped(self):
        for package in ("com.android.documentsui", "com.google.android.documentsui"):
            self.assertEqual(picker_action(xml(package), "export"), (60, 50))
            self.assertEqual(picker_action(xml(package), "import-cancel"), "back")
        for package in ("com.gunlukgorevler.gunluk_gorevler", "com.android.inputmethod.latin"):
            self.assertIsNone(picker_action(xml(package), "export"))
            self.assertIsNone(picker_action(xml(package), "export-cancel"))

    def test_only_exact_file_name_and_enabled_save_are_accepted(self):
        self.assertIsNone(picker_action(xml("com.android.documentsui", enabled="false"), "export"))
        self.assertIsNone(picker_action(xml("com.android.documentsui", text="USE THIS FOLDER"), "export"))
        tree = xml("com.android.documentsui", text="yedek.json", resource="android:id/title")
        self.assertEqual(picker_action(tree, "import", "yedek.json"), (60, 50))
        self.assertIsNone(picker_action(tree, "import", "baska.json"))

    def test_bad_or_invisible_bounds_cannot_generate_a_tap(self):
        for bounds in ("", "[0,0][0,0]", "[20,0][10,20]", "[a,0][10,20]"):
            self.assertIsNone(center(bounds))
        self.assertEqual(center("[1,2][9,12]"), (5, 7))


if __name__ == "__main__":
    unittest.main()
