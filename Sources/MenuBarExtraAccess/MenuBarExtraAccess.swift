//
//  MenuBarExtraAccess.swift
//  MenuBarExtraAccess • https://github.com/orchetect/MenuBarExtraAccess
//  © 2023 Steffan Andrews • Licensed under MIT License
//

#if os(macOS)

import SwiftUI
import Combine

@available(macOS 13.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension Scene {
    /// Adds a presentation state binding to `MenuBarExtra`.
    /// If more than one MenuBarExtra are used in the app, provide the sequential index number of the `MenuBarExtra`.
    public func menuBarExtraAccess(
        index: Int = 0,
        isPresented: Binding<Bool>,
        statusItem: ((_ statusItem: NSStatusItem) -> Void)? = nil
    ) -> some Scene {
        // FYI: SwiftUI will reinitialize the MenuBarExtra (and this view modifier)
        // if its title/label content changes, which means the stored ID will always be up-to-date
        
        MenuBarExtraAccess(
            index: index,
            statusItemIntrospection: statusItem,
            menuBarExtra: self,
            isMenuPresented: isPresented
        )
    }
}

@available(macOS 13.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct MenuBarExtraAccess<Content: Scene>: Scene {
    let index: Int
    let statusItemIntrospection: ((_ statusItem: NSStatusItem) -> Void)?
    let menuBarExtra: Content
    @Binding var isMenuPresented: Bool
    
    init(
        index: Int,
        statusItemIntrospection: ((_ statusItem: NSStatusItem) -> Void)?,
        menuBarExtra: Content,
        isMenuPresented: Binding<Bool>
    ) {
        self.index = index
        self.statusItemIntrospection = statusItemIntrospection
        self.menuBarExtra = menuBarExtra
        self._isMenuPresented = isMenuPresented
    }
    
    var body: some Scene {
        menuBarExtra
            .onChange(of: observerSetup()) { newValue in
                // do nothing here - the method runs setup when polled by SwiftUI
            }
            .onChange(of: isMenuPresented) { newValue in
                setPresented(newValue)
            }
            // .onChange(of: isToggling) { newValue in
            //    guard newValue == true else { return }
            //    togglePresented()
            //    isToggling = false
            // }
    }
    
    private func togglePresented() {
        MenuBarExtraUtils.togglePresented(for: .index(index))
    }
    
    private func setPresented(_ state: Bool) {
        MenuBarExtraUtils.setPresented(for: .index(index), state: state)
    }
    
    // MARK: Observer
    
    /// A workaround since `onAppear {}` is not available in a SwiftUI Scene.
    /// We need to set up the observer, but it can't be set up in the scene init because it needs to
    /// update scene state from an escaping closure.
    /// This returns a bogus value, but because we call it in an `onChange {}` block, SwiftUI
    /// is forced to evaluate the method and run our code at the appropriate time.
    private func observerSetup() -> Int {
        observerContainer.setupStatusItemIntrospection {
            guard let statusItem = MenuBarExtraUtils.statusItem(for: .index(index)) else { return }
            statusItemIntrospection?(statusItem)
        }
        
        observerContainer.setupObserver {
            MenuBarExtraUtils.newObserver(index: index) { change in
                guard let newVal = change.newValue else { return }
                let newBool = newVal != .off
                if isMenuPresented != newBool { isMenuPresented = newBool }
            }
        }
        
        observerContainer.setupEventsMonitor {
            MenuBarExtraUtils.newEventsMonitor { _ in
                MenuBarExtraUtils.setPresented(for: .index(index), state: false)
                isMenuPresented = false
            }
        }
        
        return 0
    }

    private var observerContainer = ObserverContainer()
    
    private class ObserverContainer {
        private var observer: NSStatusItem.ButtonStateObserver?
        private var eventsMonitor: Any?
        private var statusItemIntrospectionSetup: Bool = false

        init() { }

        func setupStatusItemIntrospection(_ block: @escaping () -> Void) {
            guard !statusItemIntrospectionSetup else { return }
            statusItemIntrospectionSetup = true
            DispatchQueue.main.async {
                block()
            }
        }

        func setupObserver(_ block: @escaping () -> NSStatusItem.ButtonStateObserver?) {
            DispatchQueue.main.async { [self] in
                observer = block()
            }
        }

        func setupEventsMonitor(_ block: @escaping () -> Any?) {
            DispatchQueue.main.async { [self] in
                eventsMonitor = block()
            }
        }
    }
}

#endif
