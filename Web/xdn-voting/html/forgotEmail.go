package html

import "fmt"

func GetEmail(password string) string {
	pass := fmt.Sprintf(`<!DOCTYPE html>
      <html lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:o="urn:schemas-microsoft-com:office:office">
      
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width,initial-scale=1">
          <meta name="x-apple-disable-message-reformatting">
          <title></title>
          <!--[if mso]>
          <noscript>
              <xml>
                  <o:OfficeDocumentSettings>
                      <o:PixelsPerInch>96</o:PixelsPerInch>
                  </o:OfficeDocumentSettings>
              </xml>
          </noscript>
          <![endif]-->
          <style>
              table, td, div, h1, p {font-family: Arial, sans-serif;}
              table, td {border:2px transparent #000000 !important;}
          </style>
      </head>
      
      
      <body style="margin:0;padding:0;">
          <table role="presentation" style="width:100%%;border-collapse:collapse;border:0;border-spacing:0;background:#ffffff;">
              <tr>
                  <td align="center" style="padding:0;">
                      <table role="presentation" style="width:602px;border-collapse:collapse;border:1px solid #cccccc;border-spacing:0;text-align:left;">
                <tr>
                  <td align="center" style="padding:40px 0 30px 0;background:#7705DD;">
                    <img src="https://www.digitalnote.org/botmail/DN2020.png" alt="" width="200" style="height:auto;display:block;" />
                  </td>
                </tr>
                <tr>
                  <td style="padding:36px 30px 42px 30px;">
                    <table role="presentation" style="width:100%%;border-collapse:collapse;border:0;border-spacing:0;">
                      <tr>
                        <td style="padding:0;">
                          <h1>Password reset</h1>
                          <p>Your new password is: <b> %s </b><br> Don't forget to change it afterwards in settings menu.</p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td align="center" style="padding:40px 0 30px 0;background:#7705DD;">
                    <a href="http://www.digitalnote.org"><img src="https://www.digitalnote.org/botmail/digitalnote-blue.png" alt="" width="200" style="height:auto;display:block;" /></a>
                  </td>
                </tr>
              </table>
                  </td>
              </tr>
          </table>
      </body>
      
      </html>`, password)
	return pass
}
