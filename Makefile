EXECUTABLE_NAME = manuscript
INSTALL_PATH = /usr/local/bin
BUILD_PATH = .build/release

.PHONY: build install uninstall clean

build:
	swift build -c release --disable-sandbox

install: build
	mkdir -p $(INSTALL_PATH)
	cp -f $(BUILD_PATH)/$(EXECUTABLE_NAME) $(INSTALL_PATH)/$(EXECUTABLE_NAME)

uninstall:
	rm -f $(INSTALL_PATH)/$(EXECUTABLE_NAME)

clean:
	swift package clean
