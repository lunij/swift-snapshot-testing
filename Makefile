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

test-ios:
	set -o pipefail && \
	xcodebuild test \
		-scheme swift-snapshot-testing-Package \
		-destination platform="iOS Simulator,name=iPhone 14,OS=16.4" \
		-resultBundlePath .xcresults/ios \
		-workspace . | xcbeautify

test-swift:
	swift test

test-tvos:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting \
		-destination platform="tvOS Simulator,name=Apple TV 4K,OS=13.3"

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Package.swift ./Sources ./Tests

test-all: test-linux test-macos test-ios
