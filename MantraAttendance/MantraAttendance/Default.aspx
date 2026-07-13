<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="MantraAttendance._Default" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Mantra MFS100 - Fingerprint Attendance</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; background: #f0f2f5; }
        .container { max-width: 720px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #1a73e8; margin-top: 0; border-bottom: 2px solid #e8eaed; padding-bottom: 15px; font-size: 24px; }
        .mode-group { margin: 20px 0; }
        .mode-group label { margin-right: 30px; cursor: pointer; font-size: 16px; }
        .mode-group input { margin-right: 6px; }
        .field { margin: 15px 0; }
        .field label { display: block; margin-bottom: 5px; font-weight: 600; color: #333; }
        .field input[type="text"] { width: 100%; padding: 10px; border: 1px solid #dadce0; border-radius: 4px; font-size: 14px; box-sizing: border-box; }
        .btn { background: #1a73e8; color: #fff; border: none; padding: 12px 30px; font-size: 16px; border-radius: 4px; cursor: pointer; }
        .btn:hover { background: #1557b0; }
        .btn:disabled { background: #ccc; cursor: not-allowed; }
        .btn-secondary { background: #5f6368; }
        .btn-secondary:hover { background: #494c50; }
        .status { margin: 15px 0; padding: 12px; border-radius: 4px; background: #e8f0fe; color: #1a73e8; }
        .status.error { background: #fce8e6; color: #d93025; }
        .status.success { background: #e6f4ea; color: #137333; }
        .result { margin: 15px 0; padding: 20px; border-radius: 4px; text-align: center; font-size: 24px; font-weight: bold; }
        .result.match { background: #e6f4ea; color: #137333; }
        .result.nomatch { background: #fce8e6; color: #d93025; }
        .enrolled-list { margin-top: 25px; border-top: 1px solid #e8eaed; padding-top: 15px; }
        .enrolled-list h3 { color: #555; }
        .enrolled-list ul { list-style: none; padding: 0; }
        .enrolled-list li { padding: 6px 10px; border-bottom: 1px solid #f0f0f0; }
        .badge { background: #e8f0fe; color: #1a73e8; padding: 2px 10px; border-radius: 12px; font-size: 12px; }
        .demobadge { background: #fef7e0; color: #e37400; padding: 4px 12px; border-radius: 4px; font-size: 13px; margin-left: 10px; }
        .info { background: #f0f4f8; padding: 10px 15px; border-radius: 4px; margin: 10px 0; color: #444; font-size: 13px; }
        .toolbar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server"></asp:ScriptManager>
        <div class="container">
            <h1>Fingerprint Attendance System</h1>
            <p style="color: #666;">Mantra MFS100 &bull; Offline Mode
                <asp:Label ID="lblDemoBadge" runat="server" CssClass="demobadge" Text="DEMO MODE" Visible="false"></asp:Label>
            </p>

            <div class="toolbar">
                <asp:Label ID="lblDeviceStatus" runat="server" CssClass="status" style="flex-grow:1;"></asp:Label>
                <asp:CheckBox ID="chkDemoMode" runat="server" Text="Demo Mode (no scanner)" AutoPostBack="true" OnCheckedChanged="chkDemoMode_CheckedChanged" />
            </div>

            <div class="mode-group">
                <asp:RadioButton ID="rbEnroll" runat="server" GroupName="Mode" Text="Enroll New User" Checked="true" onclick="toggleFields()" />
                <asp:RadioButton ID="rbVerify" runat="server" GroupName="Mode" Text="Verify Fingerprint" onclick="toggleFields()" />
            </div>

            <div class="field" id="nameField">
                <label for="txtName">Full Name:</label>
                <asp:TextBox ID="txtName" runat="server" placeholder="Enter person's full name"></asp:TextBox>
            </div>

            <div id="demoVerifyField" style="display:none;" class="field">
                <label for="ddlDemoUser">Select user to simulate verification:</label>
                <asp:DropDownList ID="ddlDemoUser" runat="server" style="width:100%;padding:10px;font-size:14px;"></asp:DropDownList>
            </div>

            <div class="toolbar">
                <asp:Button ID="btnCapture" runat="server" Text="Capture Fingerprint" CssClass="btn" OnClick="btnCapture_Click" />
                <asp:Button ID="btnInit" runat="server" Text="Re-init Scanner" CssClass="btn btn-secondary" OnClick="btnInit_Click" />
                <asp:Button ID="btnRefresh" runat="server" Text="Refresh List" CssClass="btn btn-secondary" OnClick="btnRefresh_Click" />
            </div>

            <div class="info" id="demoInfo" style="display:none;">
                <strong>Demo Mode:</strong> Click "Capture" to simulate fingerprint capture.
                For verification, select an enrolled user from the dropdown.
            </div>

            <asp:Label ID="lblStatus" runat="server" CssClass="status" Visible="false"></asp:Label>

            <asp:Panel ID="pnlResult" runat="server" Visible="false" CssClass="result">
                <asp:Label ID="lblResult" runat="server"></asp:Label>
            </asp:Panel>

            <div class="enrolled-list">
                <h3>Enrolled Users (<asp:Label ID="lblCount" runat="server" Text="0"></asp:Label>)</h3>
                <asp:BulletedList ID="blEnrolled" runat="server"></asp:BulletedList>
                <asp:Label ID="lblEmpty" runat="server" Text="No users enrolled yet." Visible="false" style="color:#888;"></asp:Label>
            </div>
        </div>
    </form>

    <script type="text/javascript">
        function toggleFields() {
            var enroll = document.getElementById('<%= rbEnroll.ClientID %>').checked;
            document.getElementById('nameField').style.display = enroll ? 'block' : 'none';
            document.getElementById('demoVerifyField').style.display = 
                (!enroll && document.getElementById('<%= chkDemoMode.ClientID %>').checked) ? 'block' : 'none';
        }

        function updateDemoUI() {
            var demo = document.getElementById('<%= chkDemoMode.ClientID %>').checked;
            document.getElementById('demoInfo').style.display = demo ? 'block' : 'none';
            document.getElementById('demoVerifyField').style.display = 
                (!document.getElementById('<%= rbEnroll.ClientID %>').checked && demo) ? 'block' : 'none';
        }

        document.getElementById('<%= chkDemoMode.ClientID %>').addEventListener('change', updateDemoUI);
    </script>
</body>
</html>
