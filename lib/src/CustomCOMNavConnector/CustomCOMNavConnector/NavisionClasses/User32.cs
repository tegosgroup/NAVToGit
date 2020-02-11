using System;
using System.Runtime.InteropServices;

namespace CustomCOMNavConnector.NavisionClasses
{
    public static class User32
    {

        [DllImport("User32.DLL")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    }
}
