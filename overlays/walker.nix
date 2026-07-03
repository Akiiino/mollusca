{ inputs }:
final: prev: {
  mollusca = (prev.mollusca or { }) // {
    walker = inputs.wrapper-manager.lib.wrapWith final {
      basePackage = prev.walker;
      pathAdd = [ final.mollusca.elephant ];
    };
  };
}
