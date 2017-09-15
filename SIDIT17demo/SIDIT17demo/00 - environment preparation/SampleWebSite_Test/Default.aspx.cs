using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class _Default : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        lblFrontend.Font.Size = 14;
        lblFrontend.Font.Bold = true;
        lblFrontend.ForeColor = System.Drawing.Color.Red;
        lblFrontend.Text = "Welcome to SID 2017 demo! This page is hosted on " + Server.MachineName;

        lblBackend.Font.Size = 14;
        lblBackend.Font.Bold = true;
        lblBackend.ForeColor = System.Drawing.Color.Blue;

        lblWebService.Font.Size = 14;
        lblWebService.Font.Bold = true;
        lblWebService.ForeColor = System.Drawing.Color.Black;


        try
        {
            simpleServiceReference.IsimpleServiceDemoClient proxy;
            if (HttpContext.Current.Request.IsSecureConnection)
            {
                proxy = new simpleServiceReference.IsimpleServiceDemoClient("BasicHttpsBinding_IsimpleServiceDemo");
            }
            else
            {
                proxy = new simpleServiceReference.IsimpleServiceDemoClient("BasicHttpBinding_IsimpleServiceDemo");
            };
            lblWebService.Text = string.Format("Invoking web service {0}", proxy.Endpoint.ListenUri.AbsoluteUri);
            lblBackend.Text = proxy.ReturnCurrentHost();
        }
        catch
        {
            lblWebService.Text = "";
            lblBackend.Text = "Backend service not available";
        }



    }
}