{
  self,
  ...
}:
{
  imports = [
    self.inputs.agenix.darwinModules.default
    self.inputs.home-manager.darwinModules.default
    self.inputs.mac-app-util.darwinModules.default
  ];
}
