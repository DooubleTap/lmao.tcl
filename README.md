<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>lmao.tcl</title>
  </head>
  <body bgcolor="#FFFFFF" text="#000000" link="#0000FF" vlink=
  "#800080" alink="#FF0000">
    <table width="790" border="0" cellspacing="0" cellpadding="0"
    align="center">
      <tr>
        <td>
          <br />
          <h1 align="center">
            lmao.tcl v1.2
          </h1><br />
          <br />
          <hr align="center" size="1" width="100%" />
          # designed to work with eggdrop 1.8 or higher<br />
          # lmao.tcl copyright (c) 2017 by Sebastien &lt; <a href="mailto:seblemery+lmaotcl@gmail.com">seblemery+lmaotcl@gmail.com</a>
          &gt;<br />
          <br />
          # Description; # This script is essential for channel
          management eggdrops. (If you desire public
          commands)<br />
          # Most basic commands that you would expect in a channel
          are included into this script.<br />
          # !help !op !deop !voice !devoice !kick !ban !bans !unban
          !perm !unperm !kban !topic<br />
          # !rehash !restart !jump !save !adduser !deluser !chattr
          !access !info<br />
          # !join !part !say !act !global !botnick !away !back !hop
          !cycle !uptime<br />
          # And more to come.<br />
          <br />
          <br />
          <h2>
            Index
          </h2>
          <ul>
            <li>
              <a href="#description">Description</a>
            </li>
            <li>
              <a href="#commands">Commands</a>
            </li>
            <li>
              <a href="#installation">Installation</a>
            </li>
            <li>
              <a href="#faq">FAQ</a>
            </li>
            <li>
              <a href="#contact">Contact</a>
            </li>
            <li>
              <a href="#disclaimer">DISCLAIMER</a>
            </li>
          </ul><br />
          <br />
          <br />
          <a name="description" id="description"></a>
          <h2>
            <a name="description" id="description">Description</a>
          </h2><a name="description" id="description"></a> This bot
          has protection scripts enabled by default when oped in a
          channel.<br />
          If you want some specific users "protected" from those,
          add them +f<br />
          <br />
          <br />
          <br />
          <a name="commands" id="commands"></a>
          <h2>
            <a name="commands" id="commands">Commands MSG/DCC</a>
          </h2><a name="commands" id="commands"></a>
          <h3>
            DCC Commands
          </h3><strong>.keepalive (f|f)</strong> - Will sent a
          blank line every 2 minutes to help you keep the
          connection in DCC<br />
          <br />
          <h3>
            Self explanatory commands
          </h3><strong>!op [nick]</strong><br />
          <strong>!deop [nick]</strong><br />
          <strong>!voice [nick]</strong><br />
          <strong>!devoice [nick]</strong><br />
          <strong>!kick [reason]</strong><br />
          <strong>!ban [reason]</strong><br />
          <strong>!perm &lt;*!*@hostname&gt;
          [reason]</strong><br />
          <br />
          <br />
          Further help is available via the DCC help system. Use
          <strong>.lmao</strong><br />
          <br />
          <br />
          <a name="installation" id="installation"></a>
          <h2>
            <a name="installation" id=
            "installation">Installation</a>
          </h2><a name="installation" id="installation"></a>
          <h3>lmao.tcl</h3>
	  Get the script from <a href="https://github.com/SebLemery/Tcl-scripts/blob/master/lmao.tcl">HERE</a><br/>
	  To install this TCL properly you have to copy it to your /scripts/ directory and add these lines to the bottom of your eggdrop.conf:
          <p>
            <br />
            <strong>source scripts/lmao.tcl</strong>
          </p>
          <p>
            <strong><br /></strong>
          </p>
          <h3>
            <strong>Settings Documentation</strong>
          </h3><br />
          <table>
            <tr>
              <td colspan="2" valign="top">
                <strong>!help [topic]</strong>
              </td>
            </tr>
            <tr>
              <td width="5" rowspan="2"></td>
              <td valign="top">
                Help system for the bot
              </td>
            </tr>
            <tr>
              <td valign="top">
                This should send you /notices with requested
                informations, i suggest you to put this page on
                your web server
              </td>
            </tr>
            <tr>
              <td colspan="3">
                &nbsp;
              </td>
            </tr>
            <tr>
              <td colspan="2" valign="top">
                <strong>Self-explained commands/b&gt;</strong>
              </td>
            </tr>
          </table><strong><br />
          <br />
          <br />
          <a name="faq" id="faq"></a></strong>
          <h2>
            <strong><a name="faq" id="faq">FAQ</a></strong>
          </h2><strong><a name="faq" id="faq"></a></strong>
          <table>
            <tr>
              <td valign="top">
                Q:
              </td>
              <td>
                &nbsp;
              </td>
              <td valign="top">
                <strong>I have a question, but it's not listed
                here.</strong>
              </td>
            </tr>
            <tr>
              <td valign="top">
                A:
              </td>
              <td>
                &nbsp;
              </td>
              <td valign="top">
                Feel free to contact the author at
                seblemery[remove]@[remove]gmail.com!
              </td>
            </tr>
            <tr>
              <td valign="top">
                Q:
              </td>
              <td>
                &nbsp;
              </td>
              <td valign="top">
                <strong>My bot does not want to start, what do i
                do?</strong>
              </td>
            </tr>
            <tr>
              <td valign="top">
                A:
              </td>
              <td>
                &nbsp;
              </td>
              <td valign="top">
                Start by unloading every scripts, and then load
                them one by one, or see a #eggdrop channel for
                help.
              </td>
            </tr>
            <tr>
              <td valign="top">
                Q:
              </td>
              <td>
                &nbsp;
              </td>
              <td valign="top">
                <strong>I have so much money, i would like to pay
                you a beer or a car, can i?</strong>
              </td>
            </tr>
            <tr>
              <td valign="top">
                A:
              </td>
              <td>
                &nbsp;
              </td>
              <td valign="top">
                Yes, you can. My paypal is my contact email below.
              </td>
            </tr>
          </table><em>Note, you don't have to tip or whatever, but
          it's always appreciated</em> :)<br />
          <br />
          <br />
          <br />
          <a name="contact" id="contact"></a>
          <h2>
            <a name="contact" id="contact">Contact</a>
          </h2><a name="contact" id="contact"></a> Contact me via
          e-mail at <a href=
          "mailto:seblemery+lmaoTCL@gmail.com">seblemery+lmaoTCL@gmail.com</a>
          , or catch me on irc usually around Undernet &amp;
          freenode<br />
          <br />
          <br />
          <a name="disclaimer" id="disclaimer"></a>
          <h2>
            <a name="disclaimer" id="disclaimer">DISCLAIMER</a>
          </h2><a name="disclaimer" id="disclaimer"></a> lmao.tcl
          is provided 'as is' and without warranty of any
          kind.<br />
          <br />
          <br />
          <hr align="center" width="50%" />
          <center>
            <font size="-1">©March 14th 2017 by Sebastien@UnderNET
            <a href="#contact">CONTACT</a></font>
          </center>
          <hr align="center" width="80%" />
        </td>
      </tr>
    </table>
  </body>
</html>
