using System;
using System.Web;

namespace MantraAttendance
{
    public class Global : HttpApplication
    {
        void Application_Start(object sender, EventArgs e)
        {
        }

        void Application_End(object sender, EventArgs e)
        {
            DeviceManager.Instance.UninitDevice();
        }

        void Application_Error(object sender, EventArgs e)
        {
        }

        void Session_Start(object sender, EventArgs e)
        {
        }

        void Session_End(object sender, EventArgs e)
        {
        }
    }
}
