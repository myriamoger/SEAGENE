
directory = getDirectory("plugins");

filelist = getFileList(directory); 

version = "not available";

for (i = 0; i < lengthOf(filelist); i++) {
    if (startsWith(filelist[i], "_camt-")){
       version = substring(filelist[i], indexOf(filelist[i], "-") + 1, lengthOf(filelist[i])-4);
    } 
}


Dialog.create("About");
	Dialog.addMessage("Detect Foci Tools", 14, "#00aa11");
	Dialog.addMessage("Detect and count gamma-H2AX foci inside nuclei\n");
	Dialog.addMessage("Version: " + version);
	Dialog.addMessage("Additional dependencies (update sites):\n" +
	"     - None\n");
	Dialog.addMessage("Inception: 2023-2025");
	Dialog.addMessage("Author 1: M. Oger", 12, "#0011aa");
	Dialog.addMessage(" \tImagery Unit, D.PRT, D.MEP, IRBA",11);
	Dialog.addMessage("Author 2: M. Cherrière", 12, "#0011aa");
	Dialog.addMessage(" \tRTE Unit, D.EBR, D.NRBC, IRBA",11);
	Dialog.addMessage(" \tINERIS",11);
	Dialog.addMessage("Beta-Test: M. Cherrière", 12, "#1100aa");
	Dialog.addHelp("");
Dialog.show();