# Covid19 Notification App - iOS Architecture

This document describes the current architecture approach for the Covid19 Notification iOS App.

## Architecture

The application is using an MVC approach with two additional patterns added:

- [Builder design pattern](https://en.wikipedia.org/wiki/Builder_pattern) - To construct objects and help with dependency management
- [Router pattern](https://www.objc.io/issues/13-architecture/viper/#routing) - A router (from the VIPER architecture) to abstract routing logic to a separate object which can reduce the amount of logic in the ViewController

All objects are defined by interfaces (`protocol`) to enable replacing them with mocked versions during (unit) testing. The [Swift API design](https://swift.org/documentation/api-design-guidelines/) guidelines are followed as much as possible. 

Examples:

- `Builder`s are defined by `Buildable` interfaces
- `Router`s are defined by `Routing` interfaces
- `ViewController`'s are defined by `ViewControllable` interfaces

### Feature

Every isolated piece of functionality/logic in the app is called a `feature`.

A feature always consists of a `Builder` together with the object it builds. In most cases `Builder`s build `Controller`s or `Router`s. Some examples:

- `Builder` builds `ViewController`
- `Builder` builds `Controller` (e.g. `networkController`, `exposureNotificationController`)
- `Builder` builds a `Router` which uses a `ViewController` to present other `viewController`s

Some examples of features are:

- ExposureController (consists of `ExposureControllerBuilder` and `ExposureController`)
- Onboarding (consists of `OnboardingBuilder`, `OnboardingRouter` and `OnboardingViewController`)

### Builder Pattern

To simplify object construction, and to remove the need to deal with dependencies during object creation, `Builder`s are used. `Builder`s can define the dependencies they require by creating a `Dependency` interface:

```
/// Specifies dependencies for the Main feature
protocol MainDependency {
    var exposureNotificationController: ExposureNotificationControlling { get }
}
```

A builder specifies which dependency it requires, or can use `EmptyDependency` if no parent dependencies are needed:

```
// 1)
protocol MainBuildable {
    func build() -> Routing
}

// 2)
final class MainDependencyProvider: DependencyProvider<MainDependency> {
}

// 3)
final class MainBuilder: Builder<MainDependency>, MainBuildable {
    func build() -> Routing {
        // `dependency` is fed into the initialiser and stored as 
        // instance variable by the Builder superclass
        let dependencyProvider = MainDependencyProvider(dependency: dependency)
        let exposureNotificationController = dependencyProvider.exposureNotificationController
        let mainViewController = MainViewController()
        
        return MainRouter(mainViewController: mainViewController, 
                          exposureNotificationController: exposureNotificationController)
    }
}
```

First, an interface is defined that describes the `MainBuilder`: its `build` function and the interface of the to-be-built object. Any dynamic dependency (for example, a `listener`) can be passed as argument to the `build` method. 

Note: Usually builders return generic interfaces (`Routing`, `ViewControllable`) to not leak implementation details to the call site. For example: it usually does not make sense for the parent to call into routing functions of a child.

Secondly, a `DependencyProvider` is created. `DependencyProvider`s can be constructed by the `Builder` to get dependencies from. Any local dependency can be constructed directly by the `DependencyProvider`:

```
final class MainDependencyProvider: DependencyProvider<MainDependency> {
    // dependencies defined here can use parent dependencies from the `dependency` variable 
    // NOTE: lazy var's are not thread safe. This is supposed to be used from the main thread.
    lazy var mainStateController: MainStateControlling = MainStateController()
} 
```

These dependencies can be used by child builders later on. For an example, see the below Router section.

Finally (3), a concrete `Builder` class is created. Its structure follows the same pattern: a `DependencyProvider` is created, any intermediate objects (in this case `mainViewController`) are created and the final `Router` is constructed and returned.

### Router

The Router concept comes from VIPER and is used to extract router specific logic. A `Router` has an associated `viewController` that it uses to route with. Usually routers call `present`/`dismiss`/`push`/`pop` methods on their `viewControllers`. ViewControllers have a **weak** reference to their router to initiate routing requests.

A feature with a router is structured as following:

`Builder` -> builds -> `Router` -> uses `ViewController` -> calls back into the same `Router`.

As the `Router` uses the `ViewController` and vice versa, both objects define each others' interfaces:

MainRouter.swift:

```
protocol MainViewControllable {
    var router: Routing? { get }

    func present(viewController: ViewControllable, animated: Bool)
    func dismiss(viewController: ViewControllable, animated: Bool)
}

final class MainRouter: Router<MainViewControllable>, MainRouting {
    init(onboardingBuilder: OnboardingBuildable) {
        self.onboardingBuilder = onboardingBuilder
    }

    // MARK: MainRouting
    
    func routeToOnboarding() {
        // construct onboarding
        let onboardingViewController = onboardingBuilder.build()
        self.onboardingViewController = onboardingViewController
        
        viewController.present(viewController: onboardingViewController, animated: true)
    }
    
    // MARK: - Private
    
    private let onboardingBuilder: OnboardingBuildable
    private var onboardingViewController: ViewControllable
}

```

MainViewController.swift:

```
protocol MainRouting: Routing {
    func routeToOnboarding()
}

final class MainViewController: ViewController, MainViewControllable {
    
    // MARK: MainViewControllable
    
    weak var router: MainRouting?
    
    func present(viewController: ViewControllable, animated: Bool) {
        // Call the UIKit function to present
        // ...
    }
    
    func dismiss(viewController: ViewControllable, animated: Bool) {
        // Call the UIKit function to dismiss
        // ...
    }
    
    // MARK: View Lifecycle
    
    func viewDidLoad() {
        super.viewDidLoad()
        
        router?.routeToOnboarding()
    }
}
```

## Conventions


- All concrete classes are defined by protocols
- Follow the [Swift API design](https://swift.org/documentation/api-design-guidelines/) guidelines to name your entities 
- Every feature should expose the smallest API possible. Instead of returning `MainRouting` from `MainBuilder`, just return `Routing`
    - Example showing difference of 'external' vs 'internal' interface: `RootBuilder` returns `AppEntryPoint`
- Use the Common UI objects provided as base classes. This will allow to easily extend common functionality in the future. If a base class is missing and you feel there's a need to have one, please add it.
- Keep the file tree organised by feature instead of Model / Controller / View 
- Use the provided `.xctemplate` for easy and consistent scaffolding
- As a rule, start with the `final` and `private` modifiers and relax when needed (by removing them, `public` is not used as everything is in one module)
- Shared extensions can go, for now, in Common/Extensions. If your extension is limited to a feature, it can live next to the feature itself
- Testing
    - Business logic and routing logic should be covered by unit tests
    - The plan for UI tests and possibly snapshot tests will be added in the future

## Mocks

[Mockolo](https://github.com/uber/mockolo) is used for generating Mocks. The `ENTests` target has a build step to generate mocks automatically. Make sure to annotate interfaces with `/// @mockable` to have mocks generated for it.

## Snapshot tests

[Snapshot Tests](https://github.com/pointfreeco/swift-snapshot-testing) are used to protect against unwanted UI changes. Ensure you commit Snapshot tests for any UI related implementations/changes. These should be run on the iPhone 12 simulator with iOS 14.4.

## Questions / Feedback / Remarks

Please use our [public GitHub repository](https://github.com/minvws/nl-covid19-notification-app-ios) for any questions or remarks.

