# DSCDemo
<P>
This repository contains PowerShell DSC demo scripts I prepared for <b><a href="https://www.sidconference.com/2017/">SID 2017 conference</a></b>.
</P>
<P>
You can generate an Azure IaaS demo environment by clicking on the following button:
<BR>
<a href="https://azuredeploy.net/?repository=https://github.com/OmegaMadLab/DSCDemo" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
</P>
<P>
<size=2><B>How to use the demo environment</B></size>
</P>
<P>
<ol>
<li>Connect to the environment via the domain controller public IP.</li>
<li>Once connected, you have to copy <b>SIDIT17demo</b> folder to the domain controller and install Remote Desktop Connection Manager; open the <b>SIDIT17-dscDemoLab.rdg</b>
and jump on the DSC Server</li>
<li>Copy folder <b>SIDIT17demo</B> on the DSC Server</li>
<li>Check variables value in <b>StartDemo.ps1</b> and execute it. It will prepare the environment, runnning scripts located in <i>00 - environment preparation</i> folder
</ol>
</P>
You can then start running demos contained in folders from 01 to 06.
<p>
Enjoy!
</p>
