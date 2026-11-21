import SwiftUI

/// Well-known Markdown files (CLAUDE.md, README.md, …) that get a labelled badge
/// in the toolbar explaining what they are, with a link to their documentation.
struct SpecialFile {
    let title: String
    let detail: String
    let icon: Icon
    let tint: Color

    enum Icon {
        case burst            // hand-drawn "splat star", used for Claude files
        case symbol(String)   // SF Symbol
    }

    static let claudeTint = Color(red: 0.85, green: 0.47, blue: 0.34)
    let docs: URL

    static func detect(_ url: URL?) -> SpecialFile? {
        guard let url else { return nil }
        let name = url.lastPathComponent.lowercased()
        let stem = url.deletingPathExtension().lastPathComponent.lowercased()
        let parent = url.deletingLastPathComponent()
        let userClaudeDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")

        switch name {
        case "claude.md":
            let detail: String
            if parent.standardizedFileURL == userClaudeDir.standardizedFileURL {
                detail = "User instructions for Claude Code. They apply to every project on this Mac."
            } else if parent.lastPathComponent == ".claude" {
                detail = "Project instructions for Claude Code, loaded whenever Claude works in \(parent.deletingLastPathComponent().lastPathComponent)."
            } else {
                detail = "Project instructions for Claude Code, loaded whenever Claude works in \(parent.lastPathComponent)."
            }
            return .init(title: "CLAUDE.md", detail: detail, icon: .burst, tint: claudeTint,
                         docs: URL(string: "https://code.claude.com/docs/en/memory")!)
        case "claude.local.md":
            return .init(title: "CLAUDE.local.md",
                         detail: "Your personal Claude Code instructions for \(parent.lastPathComponent). Usually kept out of git.",
                         icon: .burst, tint: claudeTint,
                         docs: URL(string: "https://code.claude.com/docs/en/memory")!)
        case "skill.md":
            return .init(title: "Skill",
                         detail: "A Claude Code skill named “\(parent.lastPathComponent)”. Claude loads it when a task matches its description.",
                         icon: .burst, tint: claudeTint,
                         docs: URL(string: "https://code.claude.com/docs/en/skills")!)
        case "agents.md":
            return .init(title: "AGENTS.md",
                         detail: "Instructions for AI coding agents working in \(parent.lastPathComponent).",
                         icon: .symbol("cpu"), tint: .purple, docs: URL(string: "https://agents.md")!)
        default: break
        }

        switch stem {
        case "readme":
            return .init(title: "README",
                         detail: "The overview of \(parent.lastPathComponent): what it is and how to use it. GitHub shows it on the project's front page.",
                         icon: .symbol("book.closed"), tint: .blue,
                         docs: URL(string: "https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes")!)
        case "changelog", "changes", "history":
            return .init(title: "Changelog", detail: "A record of notable changes in each release of \(parent.lastPathComponent).",
                         icon: .symbol("clock.arrow.circlepath"), tint: .teal,
                         docs: URL(string: "https://keepachangelog.com")!)
        case "contributing":
            return .init(title: "Contributing", detail: "Guidelines for contributing to \(parent.lastPathComponent).",
                         icon: .symbol("person.2"), tint: .green,
                         docs: URL(string: "https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors")!)
        case "license", "licence", "copying":
            return .init(title: "License", detail: "The terms under which \(parent.lastPathComponent) may be used and shared.",
                         icon: .symbol("checkmark.seal"), tint: .gray,
                         docs: URL(string: "https://choosealicense.com")!)
        case "security":
            return .init(title: "Security policy", detail: "How to report security vulnerabilities in \(parent.lastPathComponent).",
                         icon: .symbol("lock.shield"), tint: .red,
                         docs: URL(string: "https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository")!)
        default:
            return nil
        }
    }
}

/// A radiating "splat star": thin rays that widen toward rounded tips, at slightly
/// uneven angles and lengths so it feels hand-drawn rather than mechanical.
struct BurstShape: Shape {
    // (angle in degrees, length as fraction of radius)
    private let rays: [(CGFloat, CGFloat)] = [
        (0, 1.0), (31, 0.86), (58, 0.97), (92, 0.9), (121, 1.0), (149, 0.84),
        (181, 0.95), (209, 0.88), (238, 1.0), (268, 0.83), (298, 0.96), (328, 0.9),
    ]

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let inner = r * 0.05   // half-width at the centre
        let outer = r * 0.1    // half-width at the tip
        var path = Path()
        for (degrees, fraction) in rays {
            let length = r * fraction - outer
            var ray = Path()
            ray.move(to: CGPoint(x: -inner, y: 0))
            ray.addLine(to: CGPoint(x: -outer, y: -length))
            ray.addArc(center: CGPoint(x: 0, y: -length), radius: outer,
                       startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            ray.addLine(to: CGPoint(x: inner, y: 0))
            ray.closeSubpath()
            let t = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: degrees * .pi / 180)
            path.addPath(ray, transform: t)
        }
        path.addEllipse(in: CGRect(x: c.x - r * 0.12, y: c.y - r * 0.12, width: r * 0.24, height: r * 0.24))
        return path
    }
}

extension SpecialFile.Icon {
    @ViewBuilder
    func view(tint: Color) -> some View {
        switch self {
        case .burst:
            BurstShape().fill(tint).frame(width: 19, height: 19)
                .frame(width: 20)
        case .symbol(let name):
            Image(systemName: name).font(.system(size: 14, weight: .semibold)).foregroundStyle(tint)
                .frame(width: 20)
        }
    }
}

/// Replaces the window title: file name + reading stats. Special files get their
/// own colour and icon, and clicking the name explains the file with a docs link.
struct DocumentTitle: View {
    let name: String
    let subtitle: String
    let special: SpecialFile?
    @State private var showInfo = false

    var body: some View {
        HStack(spacing: 7) {
            special?.icon.view(tint: special!.tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(special?.tint ?? .primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture { if special != nil { showInfo.toggle() } }
        .help(special?.detail ?? name)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(special != nil ? .isButton : [])
        .popover(isPresented: $showInfo, arrowEdge: .bottom) {
            if let special {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 7) {
                        special.icon.view(tint: special.tint)
                        Text(special.title).font(.headline).foregroundStyle(special.tint)
                    }
                    Text(special.detail)
                        .fixedSize(horizontal: false, vertical: true)
                    Link(destination: special.docs) {
                        Label("Learn more", systemImage: "arrow.up.right")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .padding(16)
                .frame(width: 300, alignment: .leading)
            }
        }
    }
}
