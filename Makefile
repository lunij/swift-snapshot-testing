test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.7-focal \
		bash -c 'swift test'

test-macos:
	set -o pipefail && \
	xcodebuild test \
		-scheme swift-snapshot-testing-Package \
		-destination platform="macOS" \
		-resultBundlePath .xcresults/macos \
		-workspace . | xcbeautify

IOS_VERSION ?= 16.4

test-ios:
	set -o pipefail && \
	xcodebuild test \
		-scheme swift-snapshot-testing-Package \
		-destination platform="iOS Simulator,name=iPhone 14,OS=$(IOS_VERSION)" \
		-resultBundlePath .xcresults/ios \
		-workspace . | xcbeautify

TVOS_VERSION ?= 16.4

test-tvos:
	set -o pipefail && \
	xcodebuild test \
		-scheme swift-snapshot-testing-Package \
		-destination platform="tvOS Simulator,name=Apple TV 4K (3rd generation),OS=$(TVOS_VERSION)" \
		-resultBundlePath .xcresults/tvos \
		-workspace . | xcbeautify

VISIONOS_VERSION ?= 1.2

test-visionos:
	set -o pipefail && \
	xcodebuild test \
		-scheme swift-snapshot-testing-Package \
		-destination platform="visionOS Simulator,name=Apple Vision Pro,OS=$(VISIONOS_VERSION)" \
		-resultBundlePath .xcresults/visionos \
		-workspace . | xcbeautify

test-swift:
	swift test

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Package.swift ./Sources ./Tests

test-all: test-linux test-macos test-ios test-visionos
