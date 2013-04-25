unit gPackageLoader;

interface
uses ActiveX, Windows, gCore;
implementation
initialization
  CoInitialize(nil); // <-- manually call CoInitialize()
  G.Initialize;
finalization
  CoUnInitialize; // <-- free memory
end.
