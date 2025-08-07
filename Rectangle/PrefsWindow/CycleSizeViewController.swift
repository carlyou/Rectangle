//
//  CycleSizeViewController.swift
//  Rectangle
//
//  Created by Claude on 6/17/25.
//  Copyright © 2025 Ryan Hanson. All rights reserved.
//

import Cocoa
import MASShortcut

class CycleSizeViewController: NSViewController {

    // MARK: - IBOutlets for Storyboard UI
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var mainStackView: NSStackView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!

    // Action group containers
    @IBOutlet weak var halfScreenGroupContainer: NSStackView!
    @IBOutlet weak var quarterScreenGroupContainer: NSStackView!
    
    // Corner actions disclosure controls
    @IBOutlet weak var cornerActionsDisclosureButton: NSButton!
    @IBOutlet var cornerActionsHeightConstraint: NSLayoutConstraint!

    // Individual action containers (optional - can be created dynamically)
    @IBOutlet weak var leftHalfContainer: NSStackView?
    @IBOutlet weak var rightHalfContainer: NSStackView?
    @IBOutlet weak var topHalfContainer: NSStackView?
    @IBOutlet weak var bottomHalfContainer: NSStackView?
    @IBOutlet weak var topLeftContainer: NSStackView?
    @IBOutlet weak var topRightContainer: NSStackView?
    @IBOutlet weak var bottomLeftContainer: NSStackView?
    @IBOutlet weak var bottomRightContainer: NSStackView?
    @IBOutlet weak var centerHalfContainer: NSStackView?

    @IBOutlet weak var resetButton: NSButton!

    // Storage for dynamically created action configuration views
    private var actionConfigViews: [WindowAction: NSStackView] = [:]
    private var checkboxes: [NSButton] = []
    private var cornerActionsCollapsed = true

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStaticUI()
        setupScrollView()
        setupActionConfigViews()
        initializeAllCycleSizeConfigurations()
    }

    private func setupStaticUI() {
        // Configure static labels if they exist
        titleLabel?.stringValue = "Configure Cycle Sizes for Each Action"
        titleLabel?.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        titleLabel?.textColor = .labelColor

        subtitleLabel?.stringValue = "Customize which sizes each window action cycles through when executed repeatedly."
        subtitleLabel?.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        subtitleLabel?.textColor = .secondaryLabelColor
        subtitleLabel?.lineBreakMode = .byWordWrapping
        subtitleLabel?.maximumNumberOfLines = 0

        resetButton?.title = "Reset All to Defaults"
        resetButton?.bezelStyle = .rounded
        resetButton?.target = self
        resetButton?.action = #selector(resetToDefaults)
        
        setupCornerActionsDisclosure()
    }

    private func setupScrollView() {
        guard let scrollView = scrollView, let mainStackView = mainStackView else {
            return
        }

        // Configure scroll view properties
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        // Ensure main stack view is the document view
        if scrollView.documentView != mainStackView {
            scrollView.documentView = mainStackView
        }

        // Configure main stack view
        mainStackView.orientation = .vertical
        mainStackView.spacing = 24
        mainStackView.alignment = .leading

        // Add margins around the content
        mainStackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        // Force layout update to ensure proper scrolling
        DispatchQueue.main.async {
            self.view.needsLayout = true
            self.view.layoutSubtreeIfNeeded()

            // Ensure the scroll view content size is properly calculated
            if let documentView = scrollView.documentView {
                let contentSize = documentView.fittingSize
                documentView.setFrameSize(contentSize)
            }
        }
    }

    private func refreshScrollView() {
        guard let scrollView = scrollView else { return }

        DispatchQueue.main.async {
            // Force layout update
            self.view.needsLayout = true
            self.view.layoutSubtreeIfNeeded()

            // Update scroll view content size
            if let documentView = scrollView.documentView {
                let contentSize = documentView.fittingSize
                documentView.setFrameSize(contentSize)

                // Ensure scrollers are visible if needed
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
        }
    }

    private func setupActionConfigViews() {
        // Map outlets to actions
        if let container = leftHalfContainer {
            actionConfigViews[.leftHalf] = container
        }
        if let container = rightHalfContainer {
            actionConfigViews[.rightHalf] = container
        }
        if let container = topHalfContainer {
            actionConfigViews[.topHalf] = container
        }
        if let container = bottomHalfContainer {
            actionConfigViews[.bottomHalf] = container
        }
        if let container = topLeftContainer {
            actionConfigViews[.topLeft] = container
        }
        if let container = topRightContainer {
            actionConfigViews[.topRight] = container
        }
        if let container = bottomLeftContainer {
            actionConfigViews[.bottomLeft] = container
        }
        if let container = bottomRightContainer {
            actionConfigViews[.bottomRight] = container
        }
        if let container = centerHalfContainer {
            actionConfigViews[.centerHalf] = container
        }

        // Create containers dynamically if not connected via outlets
        let actionsToCreate: [(WindowAction, NSStackView?)] = [
            (.leftHalf, halfScreenGroupContainer),
            (.rightHalf, halfScreenGroupContainer),
            (.topHalf, halfScreenGroupContainer),
            (.bottomHalf, halfScreenGroupContainer),
            (.centerHalf, halfScreenGroupContainer),
            (.topLeft, quarterScreenGroupContainer),
            (.topRight, quarterScreenGroupContainer),
            (.bottomLeft, quarterScreenGroupContainer),
            (.bottomRight, quarterScreenGroupContainer)
        ]

        for (action, parentContainer) in actionsToCreate {
            if actionConfigViews[action] == nil, let parent = parentContainer {
                let container = createActionContainer(for: action)
                actionConfigViews[action] = container
                parent.addArrangedSubview(container)
            }
        }
    }

    private func createActionContainer(for action: WindowAction) -> NSStackView {
        let container = NSStackView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.orientation = .vertical
        container.spacing = 12
        container.alignment = .leading

        // Create horizontal container for thumbnail and title
        let titleContainer = NSStackView()
        titleContainer.orientation = .horizontal
        titleContainer.spacing = 8
        titleContainer.alignment = .centerY
        
        // Add thumbnail image
        let imageView = NSImageView()
        imageView.image = action.image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        titleContainer.addArrangedSubview(imageView)

        // Action title - larger and more prominent
        let titleLabel = NSTextField(labelWithString: action.displayName ?? action.name.capitalized)
        titleLabel.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        titleLabel.textColor = .labelColor
        titleLabel.isEditable = false
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleContainer.addArrangedSubview(titleLabel)
        
        container.addArrangedSubview(titleContainer)

        return container
    }

    private func initializeAllCycleSizeConfigurations() {
        for (action, stackView) in actionConfigViews {
            setupCycleSizeConfiguration(for: action, in: stackView)
        }

        // Refresh scroll view after adding all content
        refreshScrollView()
    }

    private func setupCycleSizeConfiguration(for action: WindowAction, in stackView: NSStackView) {
        // Get available and selected sizes
        let availableSizes = CycleSize.availableSizes(for: action)
        let selectedSizes = getCycleSizeDefault(for: action).value

        // Create checkbox container
        let checkboxContainer = createCheckboxContainer(for: action, availableSizes: availableSizes, selectedSizes: selectedSizes)
        stackView.addArrangedSubview(checkboxContainer)
    }

    private func createCheckboxContainer(for action: WindowAction, availableSizes: [CycleSize], selectedSizes: Set<CycleSize>) -> NSView {
        let container = NSStackView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.orientation = .vertical
        container.spacing = 8
        container.alignment = .leading

        // Special handling for quarter corner actions - organize in 2D grid
        let quarterActions: [WindowAction] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        if quarterActions.contains(action) {
            if let quarterSizes = organizeQuarterSizesIn2DGrid(availableSizes) {
                return createQuarter2DGridContainer(quarterSizes: quarterSizes, selectedSizes: selectedSizes, action: action)
            }
        }

        // Default layout for other actions
        let columnsPerRow = getColumnsPerRow(for: action)

        var currentRow: NSStackView?
        var itemsInCurrentRow = 0

        for (_, cycleSize) in availableSizes.enumerated() {
            if itemsInCurrentRow == 0 {
                // Create new row
                currentRow = NSStackView()
                currentRow!.translatesAutoresizingMaskIntoConstraints = false
                currentRow!.orientation = .horizontal
                currentRow!.spacing = 16
                currentRow!.alignment = .centerY
                container.addArrangedSubview(currentRow!)
            }

            let checkbox = NSButton(checkboxWithTitle: cycleSize.title, target: self, action: #selector(didCheckCycleSizeCheckbox(sender:)))
            checkbox.tag = cycleSize.rawValue
            checkbox.identifier = NSUserInterfaceItemIdentifier("\(action.name)_\(cycleSize.rawValue)")
            checkbox.state = selectedSizes.contains(cycleSize) ? .on : .off
            checkbox.isEnabled = !cycleSize.isAlwaysEnabled
            checkbox.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            
            // Set consistent width for better alignment in half actions
            let halfActions: [WindowAction] = [.leftHalf, .rightHalf, .topHalf, .bottomHalf, .centerHalf]
            if halfActions.contains(action) {
                checkbox.translatesAutoresizingMaskIntoConstraints = false
                checkbox.widthAnchor.constraint(equalToConstant: 80).isActive = true
            }

            currentRow!.addArrangedSubview(checkbox)
            checkboxes.append(checkbox)
            itemsInCurrentRow += 1

            if itemsInCurrentRow >= columnsPerRow {
                itemsInCurrentRow = 0
            }
        }

        return container
    }

    private func organizeQuarterSizesIn2DGrid(_ availableSizes: [CycleSize]) -> [[CycleSize]]? {
        guard !availableSizes.isEmpty else { return nil }

        // Extract unique width and height values and sort them
        let widthValues = Set(availableSizes.map { $0.width }).sorted()
        let heightValues = Set(availableSizes.map { $0.height }).sorted()

        guard !widthValues.isEmpty && !heightValues.isEmpty else { return nil }

        // Create 2D grid: rows = heights (ascending), columns = widths (ascending)
        var grid: [[CycleSize]] = []

        for height in heightValues {
            var row: [CycleSize] = []
            for width in widthValues {
                if let size = availableSizes.first(where: { $0.width == width && $0.height == height }) {
                    row.append(size)
                }
            }
            if !row.isEmpty {
                grid.append(row)
            }
        }

        return grid.isEmpty ? nil : grid
    }

    private func createQuarter2DGridContainer(quarterSizes: [[CycleSize]], selectedSizes: Set<CycleSize>, action: WindowAction) -> NSView {
        let container = NSStackView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.orientation = .vertical
        container.spacing = 8
        container.alignment = .leading

        guard !quarterSizes.isEmpty else {
            // Return empty container if no sizes provided
            return container
        }

        // Add header row with width labels
        if let firstRow = quarterSizes.first, !firstRow.isEmpty {
            let headerRow = NSStackView()
            headerRow.translatesAutoresizingMaskIntoConstraints = false
            headerRow.orientation = .horizontal
            headerRow.spacing = 12
            headerRow.alignment = .centerY

            // Height column header
            let heightHeader = NSTextField(labelWithString: "H↓|W→")
            heightHeader.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
            heightHeader.textColor = .secondaryLabelColor
            heightHeader.isEditable = false
            heightHeader.isBezeled = false
            heightHeader.drawsBackground = false
            heightHeader.alignment = .center
            heightHeader.translatesAutoresizingMaskIntoConstraints = false
            heightHeader.widthAnchor.constraint(equalToConstant: 50).isActive = true
            headerRow.addArrangedSubview(heightHeader)

            // Width labels (column headers)
            for cycleSize in firstRow {
                let widthLabel = NSTextField(labelWithString: formatFraction(cycleSize.width))
                widthLabel.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
                widthLabel.textColor = .secondaryLabelColor
                widthLabel.isEditable = false
                widthLabel.isBezeled = false
                widthLabel.drawsBackground = false
                widthLabel.alignment = .center
                widthLabel.translatesAutoresizingMaskIntoConstraints = false
                widthLabel.widthAnchor.constraint(equalToConstant: 70).isActive = true
                headerRow.addArrangedSubview(widthLabel)
            }

            container.addArrangedSubview(headerRow)
        }

        // Add rows with height labels and checkboxes
        for row in quarterSizes {
            let rowContainer = NSStackView()
            rowContainer.translatesAutoresizingMaskIntoConstraints = false
            rowContainer.orientation = .horizontal
            rowContainer.spacing = 12
            rowContainer.alignment = .centerY

            // Height label for this row
            if let firstSize = row.first {
                let heightLabel = NSTextField(labelWithString: formatFraction(firstSize.height))
                heightLabel.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
                heightLabel.textColor = .labelColor
                heightLabel.isEditable = false
                heightLabel.isBezeled = false
                heightLabel.drawsBackground = false
                heightLabel.alignment = .center
                heightLabel.translatesAutoresizingMaskIntoConstraints = false
                heightLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
                rowContainer.addArrangedSubview(heightLabel)
            }

            // Checkboxes for this row
            for cycleSize in row {
                let checkbox = NSButton(checkboxWithTitle: formatGridCellTitle(cycleSize), target: self, action: #selector(didCheckCycleSizeCheckbox(sender:)))
                checkbox.tag = cycleSize.rawValue
                checkbox.identifier = NSUserInterfaceItemIdentifier("\(action.name)_\(cycleSize.rawValue)")
                checkbox.state = selectedSizes.contains(cycleSize) ? .on : .off
                checkbox.isEnabled = !cycleSize.isAlwaysEnabled
                checkbox.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
                checkbox.translatesAutoresizingMaskIntoConstraints = false
                checkbox.widthAnchor.constraint(equalToConstant: 70).isActive = true


                rowContainer.addArrangedSubview(checkbox)
                checkboxes.append(checkbox)
            }

            container.addArrangedSubview(rowContainer)
        }

        return container
    }

    private func formatFraction(_ value: Float) -> String {
        switch value {
        case 0.25: return "¼"
        case 1.0/3.0: return "⅓"
        case 0.5: return "½"
        case 2.0/3.0: return "⅔"
        case 0.75: return "¾"
        case 1.0: return "1"
        default: return String(format: "%.2f", value)
        }
    }

    private func formatGridCellTitle(_ cycleSize: CycleSize) -> String {
        // For grid cells, show the dimensions more compactly
        return "\(formatFraction(cycleSize.width))×\(formatFraction(cycleSize.height))"
    }

    private func getColumnsPerRow(for action: WindowAction) -> Int {
        switch action {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return 3 // Corner actions have many combinations, use fewer columns
        default:
            return 5 // Other actions can use more columns
        }
    }

    @objc private func didCheckCycleSizeCheckbox(sender: Any?) {

        guard let checkbox = sender as? NSButton else {
            return
        }

        guard let identifier = checkbox.identifier?.rawValue else {
            return
        }

        guard let action = getActionFromIdentifier(identifier) else {
            return
        }

        guard let cycleSize = CycleSize(rawValue: checkbox.tag) else {
            return
        }

        let cycleSizeDefault = getCycleSizeDefault(for: action)

        if checkbox.state == .on {
            cycleSizeDefault.value.insert(cycleSize)
        } else {
            cycleSizeDefault.value.remove(cycleSize)
        }

    }

    private func getActionFromIdentifier(_ identifier: String) -> WindowAction? {
        let components = identifier.components(separatedBy: "_")
        guard components.count >= 1 else { return nil }
        let actionName = components[0]
        return actionConfigViews.keys.first { $0.name == actionName }
    }

    private func getCycleSizeDefault(for action: WindowAction) -> ActionCycleSizesDefault {
        switch action {
        case .leftHalf: return Defaults.leftHalfCycleSizes
        case .rightHalf: return Defaults.rightHalfCycleSizes
        case .topHalf: return Defaults.topHalfCycleSizes
        case .bottomHalf: return Defaults.bottomHalfCycleSizes
        case .topLeft: return Defaults.topLeftCycleSizes
        case .topRight: return Defaults.topRightCycleSizes
        case .bottomLeft: return Defaults.bottomLeftCycleSizes
        case .bottomRight: return Defaults.bottomRightCycleSizes
        case .centerHalf: return Defaults.centerHalfCycleSizes
        default: fatalError("Action \(action) does not support cycle sizes")
        }
    }

    @IBAction func resetToDefaults(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Reset Cycle Sizes"
        alert.informativeText = "This will reset all cycle size configurations to their defaults. Are you sure?"
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            resetAllCycleSizesToDefaults()
        }
    }

    private func resetAllCycleSizesToDefaults() {
        for action in actionConfigViews.keys {
            let cycleSizeDefault = getCycleSizeDefault(for: action)
            cycleSizeDefault.value = CycleSize.defaultSizes(for: action)
        }

        // Refresh the UI
        initializeAllCycleSizeConfigurations()

        // Ensure scroll view is properly updated
        refreshScrollView()
    }
    
    private func setupCornerActionsDisclosure() {
        cornerActionsDisclosureButton?.title = "▶︎ Corner Actions"
        cornerActionsDisclosureButton?.target = self
        cornerActionsDisclosureButton?.action = #selector(toggleCornerActions)
        cornerActionsDisclosureButton?.isBordered = false
        cornerActionsDisclosureButton?.bezelStyle = .inline
        cornerActionsDisclosureButton?.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        
        // Start collapsed
        quarterScreenGroupContainer?.isHidden = true
        cornerActionsHeightConstraint?.isActive = true
    }
    
    @IBAction func toggleCornerActions(_ sender: NSButton) {
        cornerActionsCollapsed = !cornerActionsCollapsed
        
        animateChanges(animated: true) {
            self.quarterScreenGroupContainer?.isHidden = self.cornerActionsCollapsed
            self.cornerActionsHeightConstraint?.isActive = self.cornerActionsCollapsed
        }
        
        // Update button title with disclosure triangle
        cornerActionsDisclosureButton?.title = cornerActionsCollapsed
            ? "▶︎ Corner Actions"
            : "▼ Corner Actions"
        
        // Refresh scroll view after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.refreshScrollView()
        }
    }
    
    private func animateChanges(animated: Bool, block: () -> Void) {
        if animated {
            NSAnimationContext.runAnimationGroup({context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                
                block()
                view.layoutSubtreeIfNeeded()
            }, completionHandler: nil)
        } else {
            block()
        }
    }
}
