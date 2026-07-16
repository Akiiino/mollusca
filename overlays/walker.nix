# walker spawns elephant (its search backend) by name, so we put ours on PATH.
{ inputs }:
final: prev: {
  mollusca = (prev.mollusca or { }) // {
    walker = inputs.wrapper-manager.lib.wrapWith final {
      basePackage = prev.walker;
      pathAdd = [ final.mollusca.elephant ];
    };
  };
}
