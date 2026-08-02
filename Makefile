test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.7-focal \
		bash -c 'swift test'

test-macos:
	set -o pipefail && \
	TEST_RUNNER_CI=$(CI) \
	xcodebuild test \
		-scheme swift-snapshotting-Package \
		-destination platform="macOS" \
		-resultBundlePath .xcresults/macos \
		-workspace . | xcbeautify

test-ios:
	set -o pipefail && \
	TEST_RUNNER_CI=$(CI) \
	xcodebuild test \
		-scheme swift-snapshotting-Package \
		-destination platform="iOS Simulator,name=iPhone 17,OS=26.4.1" \
		-resultBundlePath .xcresults/ios \
		-workspace . | xcbeautify

test-swift:
	swift test

test-tvos:
	set -o pipefail && \
	TEST_RUNNER_CI=$(CI) \
	xcodebuild test \
		-scheme swift-snapshotting-Package \
		-destination platform="tvOS Simulator,name=Apple TV 4K (3rd generation),OS=26.4" \
		-resultBundlePath .xcresults/tvos \
		-workspace . | xcbeautify

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Package.swift ./Sources ./Tests

lint:
	swift format lint --recursive Sources Tests

docs:
	./Scripts/build-documentation.sh

test-all: test-linux test-macos test-ios test-tvos
