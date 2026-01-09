# Makefile for Sleep Timer Media Player
# Build the macOS app and create distributable DMG

# Configuration
APP_NAME = SleepPlayer
SCHEME = SleepPlayer
PROJECT = SleepPlayer.xcodeproj
CONFIGURATION = Release
BUILD_DIR = build
DERIVED_DATA = $(BUILD_DIR)/DerivedData

# Paths
APP_PATH = $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/$(APP_NAME).app
DMG_NAME = $(APP_NAME).dmg
DMG_VOLUME_NAME = "Sleep Timer Media Player"
DMG_TEMP = $(BUILD_DIR)/dmg_temp

# Version (you can override this: make dmg VERSION=1.4.0)
VERSION ?= 1.4.0

.PHONY: all build clean run dmg help install

# Default target
all: build

help:
	@echo "Sleep Timer Media Player - Build Commands"
	@echo "=========================================="
	@echo ""
	@echo "Available targets:"
	@echo "  make build      - Build the application (Release configuration)"
	@echo "  make debug      - Build the application (Debug configuration)"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make run        - Build and run the application"
	@echo "  make dmg        - Create a distributable DMG file"
	@echo "  make install    - Install the app to /Applications"
	@echo "  make test       - Run unit tests (if available)"
	@echo "  make help       - Show this help message"
	@echo ""
	@echo "Options:"
	@echo "  VERSION=x.x.x   - Set version for DMG (default: $(VERSION))"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make dmg VERSION=1.2.0"
	@echo "  make clean && make build"

# Build the application (Release)
build:
	@echo "Building $(APP_NAME) in $(CONFIGURATION) mode..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		build
	@echo ""
	@echo "✓ Build complete: $(APP_PATH)"

# Build debug version
debug:
	@echo "Building $(APP_NAME) in Debug mode..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(DERIVED_DATA) \
		build
	@echo ""
	@echo "✓ Debug build complete"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		clean
	rm -rf $(BUILD_DIR)
	rm -f $(DMG_NAME)
	@echo "✓ Clean complete"

# Build and run the application
run: build
	@echo "Launching $(APP_NAME)..."
	open $(APP_PATH)

# Install to /Applications
install: build
	@echo "Installing $(APP_NAME) to /Applications..."
	@if [ -d "/Applications/$(APP_NAME).app" ]; then \
		echo "Removing existing installation..."; \
		rm -rf "/Applications/$(APP_NAME).app"; \
	fi
	cp -R $(APP_PATH) /Applications/
	@echo "✓ Installed to /Applications/$(APP_NAME).app"

# Create DMG for distribution
dmg: build
	@echo "Creating DMG for $(APP_NAME) v$(VERSION)..."
	@# Clean up any existing DMG and temp folder
	rm -rf $(DMG_TEMP)
	rm -f $(DMG_NAME)

	@# Create temporary folder for DMG contents
	mkdir -p $(DMG_TEMP)

	@# Copy the application
	cp -R $(APP_PATH) $(DMG_TEMP)/

	@# Create a symbolic link to /Applications
	ln -s /Applications $(DMG_TEMP)/Applications

	@# Create a .DS_Store file for better DMG appearance (optional)
	@# This would require additional AppleScript or custom tools

	@# Create the DMG
	@echo "Creating disk image..."
	hdiutil create -volname $(DMG_VOLUME_NAME) \
		-srcfolder $(DMG_TEMP) \
		-ov \
		-format UDZO \
		-imagekey zlib-level=9 \
		$(DMG_NAME)

	@# Clean up temp folder
	rm -rf $(DMG_TEMP)

	@echo ""
	@echo "✓ DMG created: $(DMG_NAME)"
	@echo "  Volume name: $(DMG_VOLUME_NAME)"
	@echo "  Version: $(VERSION)"
	@ls -lh $(DMG_NAME)

# Run tests (if you add tests later)
test:
	@echo "Running tests..."
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-derivedDataPath $(DERIVED_DATA)

# Archive for distribution
archive:
	@echo "Creating archive for distribution..."
	xcodebuild archive \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-archivePath $(BUILD_DIR)/$(APP_NAME).xcarchive
	@echo "✓ Archive created: $(BUILD_DIR)/$(APP_NAME).xcarchive"

# Show build settings
show-settings:
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-showBuildSettings

# Check code for issues
lint:
	@echo "Running SwiftLint (if installed)..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "SwiftLint not installed. Install with: brew install swiftlint"; \
	fi
