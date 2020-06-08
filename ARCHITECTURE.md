# Covid19 Notification App - iOS Architecture

This document describes the architecture approach for the Covid19 Notification App.

### Architecture

The application is based using an MVC approach. On top of it two additional patterns are added:

- [Builder design pattern](https://en.wikipedia.org/wiki/Builder_pattern) - To construct objects and help with dependency management
- [Router pattern] (https://www.objc.io/issues/13-architecture/viper/#routing) - A router (from the VIPER architecture) can be used to move routing logic to a separate object to reduce the amount of logic in the ViewController

All objects are defined by interfaces (`protocol`) to enable exchanging them with mocked versions during unit testing. The [Swift API design](https://swift.org/documentation/api-design-guidelines/) guidelines are followed as much as possible. 

Examples:

- `Builder`s are defined by `Buildable` interfaces
- `Router`s are defined by `Routing` interfaces
- `ViewController`'s are defined by `ViewControllable` interfaces

#### Component

Every isolated piece of functionality/logic in the app is called a component.

A component always consists of a `Builder` together with the object it builds. In most cases `Builder`s build `Controller`s or `Router`s. Some examples:

- `Builder` builds `ViewController`
- `Builder` builds `Controller` (e.g. `networkController`, `exposureNotificationController`)
- `Builder` builds a `Router` which uses a `ViewController` to present other `viewController`s

Some examples of Components are:

- ExposureNotification (consists of `ExposureNotificationBuilder` and `ExposureNotificationController`)
- Onboarding (consists of `OnboardingBuilder`, `OnboardingRouter` and `OnboardingViewController`)

#### Builder Pattern

To simplify object construction and to remove the need to worry about dependencies during object creation `Builder`s are used. `Builder`s can define the dependencies they require by specifying a `Dependency` interface:

```
protocol MainDependency {
    var exposureNotificationController: ExposureNotificationControlling { get }
}
```

A builder specifies this dependency, or can use `EmptyDependency` if no parent dependencies are needed:

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

First, an interface is defined that describes the `MainBuilder`: it's `build` function and the interface that describes the object that's being built. Any dynamic dependency (for example, a `listener`) can be passed as argument to the `build` method. Usually builders return generic interfaces (Routing, ViewControllable) to not leak implementation details to the call site. For example: it usually does not make sense for the parent to call into routing functions of a child.

Secondly, a `DependencyProvider` is created. DependencyProviders can be constructed by the Builder to get dependencies from. Any local dependencies can be constructed directly in the DependencyProvider:

```
final class MainDependencyProvider: DependencyProvider<MainDependency> {
    // dependencies defined here can use parent dependencies from the `dependency` variable 
    lazy var mainStateController: MainStateControlling = MainStateController()
} 
```

These dependencies can be used by child builders later on. For an example, see the below Router section.

Finally (3), a concrete `Builder` class is created. It's structure follows the same pattern: a DependencyProvider is created, any intermediate objects (in this case `mainViewController`) is created and the final Router is constructed and returned.

#### Router

The Router concept comes from VIPER and is used to extract router specific logic. A `Router` has an associated `viewController` that it uses to route with. Usually routers call `present`/`dismiss`/`push`/`pop` calls on their `viewControllers`. ViewControllers call their router to perform specific router operations.

A Component with a router looks as follows:

`Builder` -> builds -> `Router` -> uses `ViewController` -> calls back into the same `Router`.

As the Router uses the ViewController and vice versa, both objects define each others interfaces:

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
