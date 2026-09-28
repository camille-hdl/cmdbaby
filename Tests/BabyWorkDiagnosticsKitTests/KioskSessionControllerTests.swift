import Testing

@testable import BabyWorkDiagnosticsKit

@MainActor
@Test("L’activation couvre chaque écran, y compris une origine négative")
func activationCoversEveryScreenIncludingNegativeOrigin() async {
  let services = FakeKioskServices(screens: threeTargetScreens)
  let controller = KioskSessionController(services: services)

  let state = await controller.activate()

  #expect(state.phase == .active)
  #expect(state.coveredScreens.count == 3)
  #expect(state.coveredScreens.contains { $0.hasNegativeOrigin })
  #expect(state.coveredScreens.contains { $0.isMain })
  #expect(services.openWindows == threeTargetScreens)
  #expect(services.currentPresentation == KioskPresentationPolicy.kiosk)
  #expect(services.filterRunning)
  #expect(state.lastError == nil)
}

@MainActor
@Test("Le filtre est armé avant la création des fenêtres")
func filterStartsBeforeCoverWindows() async {
  let services = FakeKioskServices(screens: threeTargetScreens)
  let controller = KioskSessionController(services: services)

  _ = await controller.activate()

  #expect(
    services.operations == [
      "stopInputFilter",
      "capturePresentation",
      "hideDiagnosticInterface",
      "startInputFilter",
      "createCoverWindows",
      "applyKioskPresentation",
    ]
  )
}

@MainActor
@Test("Les clics de secours arrêtent le kiosque")
func failsafeClickDeactivatesKiosk() async {
  let services = FakeKioskServices(screens: threeTargetScreens)
  let controller = KioskSessionController(services: services)
  _ = await controller.activate()

  let state = controller.deactivate(exitKind: .failsafeClick)

  #expect(state.phase == .configuration)
  #expect(state.lastExitKind == .failsafeClick)
  assertIdleWithoutSessionResources(services)
}

@MainActor
@Test("Une sortie adulte laisse l’idle sans couverture, filtre ni ressources de mode")
func adultExitLeavesIdleWithoutSessionResources() async {
  let services = FakeKioskServices(screens: threeTargetScreens)
  let controller = KioskSessionController(services: services)
  _ = await controller.activate()
  #expect(services.playModeResourcesLoaded)
  #expect(services.filterHeld)

  let state = controller.deactivate(exitKind: .passphrase)

  #expect(state.phase == .configuration)
  #expect(state.coveredScreens.isEmpty)
  #expect(!state.blocksTermination)
  assertIdleWithoutSessionResources(services)
}

@MainActor
@Test("Une nouvelle session démarre après une sortie adulte")
func activationSucceedsAfterAdultExit() async {
  let services = FakeKioskServices(screens: threeTargetScreens)
  let controller = KioskSessionController(services: services)
  _ = await controller.activate()
  _ = controller.deactivate(exitKind: .timeLimit)

  let state = await controller.activate()

  #expect(state.phase == .active)
  #expect(state.coveredScreens.count == 3)
  #expect(services.openWindows.count == 3)
  #expect(services.filterRunning)
  #expect(services.filterHeld)
  #expect(services.playModeResourcesLoaded)
  #expect(services.currentPresentation == KioskPresentationPolicy.kiosk)
}

@MainActor
@Test("L’arrêt restaure exactement les options de présentation mémorisées")
func deactivationRestoresExactCapturedPresentation() async {
  let original = PresentationOptionsSnapshot(rawValue: 16)
  let services = FakeKioskServices(
    screens: threeTargetScreens,
    initialPresentation: original
  )
  let controller = KioskSessionController(services: services)

  _ = await controller.activate()
  let state = controller.deactivate(exitKind: .passphrase)

  #expect(state.phase == .configuration)
  #expect(state.lastExitKind == .passphrase)
  #expect(state.coveredScreens.isEmpty)
  assertIdleWithoutSessionResources(services)
  #expect(services.currentPresentation == original)
  #expect(services.restoredSnapshots == [original])
}

@MainActor
@Test("Commande-Q n’est pas une sortie et n’arrête pas le kiosque")
func commandQDoesNotDeactivateKiosk() async {
  let services = FakeKioskServices(screens: threeTargetScreens)
  let controller = KioskSessionController(services: services)
  _ = await controller.activate()

  #expect(
    ShortcutSuppressionPolicy.decision(
      keyCode: MacVirtualKeyCode.ansiQ,
      modifiers: [.command],
      letter: "q"
    ) == .suppress(.commandQ)
  )
  #expect(controller.state.phase == .active)
  #expect(services.filterRunning)
}

@MainActor
@Test("Sans écran, l’activation échoue et ne laisse aucun résidu")
func missingScreensRollBackCleanly() async {
  let original = PresentationOptionsSnapshot(rawValue: 4)
  let services = FakeKioskServices(screens: [], initialPresentation: original)
  let controller = KioskSessionController(services: services)

  let state = await controller.activate()

  #expect(state.phase == .failed)
  #expect(state.lastError == .noScreens)
  assertNoKioskResidue(services, originalPresentation: original)
}

@MainActor
@Test(
  "Une défaillance injectée à chaque étape déclenche un rollback sans résidu",
  arguments: KioskPrepStep.allCases
)
func injectedFailureAtEachStepRollsBack(step: KioskPrepStep) async {
  let original = PresentationOptionsSnapshot(rawValue: 32)
  let services = FakeKioskServices(
    screens: threeTargetScreens,
    initialPresentation: original
  )
  let controller = KioskSessionController(services: services)
  controller.injectedFailure = step

  let state = await controller.activate()

  #expect(state.phase == .failed)
  #expect(state.lastError == .injectedFailure(step))
  assertNoKioskResidue(services, originalPresentation: original)
}

@MainActor
@Test("Une nouvelle activation réussit après un rollback")
func activationSucceedsAfterInjectedFailure() async {
  let services = FakeKioskServices(screens: threeTargetScreens)
  let controller = KioskSessionController(services: services)
  controller.injectedFailure = .applyPresentation
  _ = await controller.activate()

  controller.injectedFailure = nil
  let state = await controller.activate()

  #expect(state.phase == .active)
  #expect(services.openWindows.count == 3)
  #expect(services.filterRunning)
  #expect(services.currentPresentation == KioskPresentationPolicy.kiosk)
}

@MainActor
private func assertNoKioskResidue(
  _ services: FakeKioskServices,
  originalPresentation: PresentationOptionsSnapshot
) {
  assertIdleWithoutSessionResources(services)
  #expect(services.currentPresentation == originalPresentation)
}

@MainActor
private func assertIdleWithoutSessionResources(_ services: FakeKioskServices) {
  #expect(services.openWindows.isEmpty)
  #expect(!services.filterRunning)
  #expect(!services.filterHeld)
  #expect(!services.playModeResourcesLoaded)
}

private let threeTargetScreens = [
  ScreenDescriptor(
    id: "built-in",
    name: "Built-in Retina Display",
    originX: 0,
    originY: 0,
    width: 1512,
    height: 982,
    scale: 2,
    isMain: true
  ),
  ScreenDescriptor(
    id: "rog",
    name: "ROG PG279Q",
    originX: 2259,
    originY: 881,
    width: 2560,
    height: 1440,
    scale: 2,
    isMain: false
  ),
  ScreenDescriptor(
    id: "msi",
    name: "MSI MAG323UPF",
    originX: -749,
    originY: 982,
    width: 3008,
    height: 1692,
    scale: 2,
    isMain: false
  ),
]

@MainActor
private final class FakeKioskServices: KioskSessionServices {
  var screens: [ScreenDescriptor]
  let initialPresentation: PresentationOptionsSnapshot
  var currentPresentation: PresentationOptionsSnapshot
  var openWindows: [ScreenDescriptor] = []
  var filterRunning = false
  var filterHeld = false
  var playModeResourcesLoaded = false
  var restoredSnapshots: [PresentationOptionsSnapshot] = []
  var operations: [String] = []

  init(
    screens: [ScreenDescriptor],
    initialPresentation: PresentationOptionsSnapshot = PresentationOptionsSnapshot(rawValue: 0)
  ) {
    self.screens = screens
    self.initialPresentation = initialPresentation
    self.currentPresentation = initialPresentation
  }

  func capturePresentation() throws -> PresentationOptionsSnapshot {
    operations.append("capturePresentation")
    return currentPresentation
  }

  func createCoverWindows() throws -> [ScreenDescriptor] {
    operations.append("createCoverWindows")
    guard !screens.isEmpty else { throw KioskSessionError.noScreens }
    openWindows = screens
    playModeResourcesLoaded = true
    return screens
  }

  func applyKioskPresentation() throws {
    operations.append("applyKioskPresentation")
    currentPresentation = KioskPresentationPolicy.kiosk
  }

  func startInputFilter() async throws {
    operations.append("startInputFilter")
    filterRunning = true
    filterHeld = true
  }

  func restorePresentation(_ snapshot: PresentationOptionsSnapshot) {
    operations.append("restorePresentation")
    restoredSnapshots.append(snapshot)
    currentPresentation = snapshot
  }

  func closeCoverWindows() {
    operations.append("closeCoverWindows")
    openWindows = []
    playModeResourcesLoaded = false
  }

  func stopInputFilter() {
    operations.append("stopInputFilter")
    filterRunning = false
    filterHeld = false
  }

  func hideDiagnosticInterface() {
    operations.append("hideDiagnosticInterface")
  }
}
