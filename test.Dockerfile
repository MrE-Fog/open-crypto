FROM swift:4.2
COPY Sources/ Sources/
COPY Tests/ Tests/
COPY Package.swift Package.swift
ENTRYPOINT swift test
