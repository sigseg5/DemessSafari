//
//  BookmarkManager.swift
//  DemessSafari
//

import Foundation
import AppKit
import UniformTypeIdentifiers
import SwiftUI

struct BookmarkEntry: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let url: URL?
    let path: String
}

class BookmarkManager: ObservableObject {
    @Published var entries: [BookmarkEntry] = []
    @Published var exactDuplicates: [[BookmarkEntry]] = []
    @Published var domainDuplicates: [[BookmarkEntry]] = []
    
    func loadBookmarks() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.propertyList]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Select Safari Bookmarks File"
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Safari")
        guard panel.runModal() == .OK, let bookmarksURL = panel.url else {
            print("No file selected")
            return
        }
        
        guard let data = try? Data(contentsOf: bookmarksURL) else {
            print("Could not read Bookmarks.plist")
            return
        }
        
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard let plist = try? PropertyListSerialization.propertyList(
            from: data,
            options: .mutableContainersAndLeaves,
            format: &format
        ) as? [String: Any] else {
            print("Could not parse plist")
            return
        }
        
        let children = plist["Children"] as? [[String: Any]] ?? []
        var allEntries: [BookmarkEntry] = []
        parse(children, currentPath: "Safari Bookmarks", into: &allEntries)
        DispatchQueue.main.async {
            self.entries = allEntries
            self.computeDuplicates(from: allEntries)
        }
    }
    
    private func parse(_ items: [[String: Any]], currentPath: String, into result: inout [BookmarkEntry]) {
        for item in items {
            let type  = item["WebBookmarkType"] as? String
            let title = (item["Title"] as? String)
            ?? ((item["URIDictionary"] as? [String: Any])?["title"] as? String)
            ?? "Untitled"
            let newPath = currentPath + " → " + title
            
            if type == "WebBookmarkTypeList", let subs = item["Children"] as? [[String: Any]] {
                parse(subs, currentPath: newPath, into: &result)
            }
            else if type == "WebBookmarkTypeLeaf" {
                let urlString = item["URLString"] as? String ?? ""
                let url = URL(string: urlString)
                result.append(BookmarkEntry(title: title, url: url, path: newPath))
            }
        }
    }
    
    private func computeDuplicates(from list: [BookmarkEntry]) {
        // Exact URL duplicates
        let urlGroups = Dictionary(grouping: list, by: { $0.url?.absoluteString ?? "" })
        exactDuplicates = urlGroups.values.filter { $0.count > 1 }
        
        // Only exact URL duplicates
        domainDuplicates = exactDuplicates
    }
}
