//
//  ContentView.swift
//  DemessSafari
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var manager = BookmarkManager()

    var body: some View {
        VStack {
            Text("Domain duplicates: \(manager.domainDuplicates.count)")
                .font(.headline)
                .padding(.top)
            List {
                ForEach(manager.domainDuplicates, id: \.self) { group in
                    if let host = group.first?.url?.host {
                        Section(header: Text("Host: \(host)")
                                    .font(.subheadline)
                                    .padding(.vertical, 4)
                                    .textSelection(.enabled)) {
                            ForEach(group, id: \.path) { entry in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Title: \(entry.title)")
                                    if let url = entry.url {
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text("URL:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Link(url.absoluteString, destination: url)
                                                .font(.caption)
                                                .textSelection(.enabled)
                                                .onHover { hovering in
                                                    if hovering {
                                                        NSCursor.pointingHand.push()
                                                    } else {
                                                        NSCursor.pop()
                                                    }
                                                }
                                        }
                                    } else {
                                        Text("URL: ")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .textSelection(.enabled)
                                    }
                                    Text("Path: \(entry.path)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                                .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                manager.loadBookmarks()
            }
        }
    }
}
