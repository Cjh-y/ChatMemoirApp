import SwiftUI; import Foundation

// MARK: - Models
struct MemoryItem: Identifiable, Codable { var id: String = UUID().uuidString; var type: String = "text"; var content: String; var date: Date = Date() }
struct MemBook: Identifiable, Codable { var id: String = UUID().uuidString; var title: String; var memories: [MemoryItem]; var createdAt: Date = Date() }
struct Book: Identifiable { let id = UUID().uuidString; let title: String; let subtitle: String; let chapters: [Chap] }
struct Chap: Identifiable { let id = UUID().uuidString; let title: String; let pages: [String] }
struct Demo: Identifiable { let id: String; let title: String; let subtitle: String; let desc: String
    func build() -> Book {
        let pages: [String]
        switch id {
        case "alice": pages = ["2023年3月15日\n第一条消息。","从你好到晚安\n慢慢地，每天都是这样。","2024年春节\n互相发了很长的祝福。","那年夏天聊得最多\n经常聊到凌晨。","到今年已经两年多了\n不知不觉。"]
        case "bob":   pages = ["2021年6月\n深夜第一次长聊。","经常凌晨一两点\n聊工作、人生。","三年了\n谢谢你听我说那么多。"]
        case "family": pages = ["2020年\n我们家的群聊。","每次节日\n妈妈都问：回来吃饭吗？","1800天了\n家永远是最温暖的地方。"]
        default: pages = []
        }
        return Book(title: title, subtitle: subtitle, chapters: [Chap(title: "我们的故事", pages: pages)])
    }
    static let alice = Demo(id:"alice",title:"Alice 与我",subtitle:"温暖日常",desc:"两年半的聊天。")
    static let bob   = Demo(id:"bob",title:"Bob 与我",subtitle:"深夜对话",desc:"三年深夜聊了无数次。")
    static let family = Demo(id:"family",title:"我们的家",subtitle:"群聊记忆",desc:"一家四口的群聊。")
}

// MARK: - StoryBuilder
struct StoryBuilder {
    static func build(title: String, subtitle: String, from items: [MemoryItem]) -> Book {
        let sorted = items.sorted { $0.date < $1.date }
        let df = DateFormatter(); df.dateFormat = "yyyy年M月d日"
        let pages = sorted.map { df.string(from: $0.date) + "\n" + $0.content }
        return Book(title: title, subtitle: subtitle, chapters: [Chap(title: "我们的故事", pages: pages)])
    }
}

// MARK: - Repository
@MainActor final class Repository: ObservableObject {
    @Published var books: [MemBook] = []
    private let url: URL
    init() {
        url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("memoirs.json")
        load()
    }
    func createBook(title: String, memories: [MemoryItem]) {
        let b = MemBook(title: title, memories: memories)
        books.append(b); save()
    }
    func deleteBook(id: String) { books.removeAll { $0.id == id }; save() }
    private func save() { if let d = try? JSONEncoder().encode(books) { try? d.write(to: url) } }
    private func load() { if let d = try? Data(contentsOf: url), let b = try? JSONDecoder().decode([MemBook].self, from: d) { books = b } }
}

// MARK: - App
enum AppPhase: Equatable { case welcome; case pick; case memory; case gen; case reader }
@main struct ChatMemoirApp: App {
    @StateObject private var repo = Repository()
    @State private var phase: AppPhase = .welcome
    @State private var book: Book?
    let demos: [Demo] = [.alice, .bob, .family]
    var body: some Scene { WindowGroup {
        ZStack {
            switch phase {
            case .welcome: WelcomeScreen { phase = .pick }
            case .pick:    PickScreen(demos: demos, repo: repo, onMemory: { phase = .memory }, onPick: { b in book = b; phase = .gen })
            case .memory:  MemoryScreen(repo: repo, onDone: { phase = .pick })
            case .gen:     GenScreen { phase = .reader }
            case .reader:  if let b = book { ReaderScreen(book: b) { phase = .pick } }
            }
        }
        .animation(.easeInOut(duration: 0.6), value: phase)
    } }
}

// MARK: - Paper Background
struct PaperBg<Content: View>: View {
    @Environment(\.colorScheme) var cs
    let c: Content
    init(@ViewBuilder _ c: () -> Content) { self.c = c() }
    var body: some View {
        ZStack {
            (cs == .dark ? Color(red:0.12,green:0.11,blue:0.10) : Color(red:0.96,green:0.94,blue:0.90)).ignoresSafeArea()
            c
        }
    }
}

// MARK: - Welcome
struct WelcomeScreen: View {
    let onStart: () -> Void
    @State private var a = false
    var body: some View {
        PaperBg {
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) {
                    Text("ChatMemoir").font(.system(.largeTitle, design: .serif)).fontWeight(.medium).tracking(3).foregroundStyle(.primary.opacity(0.85))
                    Text("把值得珍藏的聊天，\n做成一本真正属于你的书。").font(.system(.body, design: .serif)).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(6)
                }
                .opacity(a ? 1 : 0).offset(y: a ? 0 : 20)
                Spacer()
                Button("开始制作") { onStart() }
                    .font(.system(.body, design: .serif)).foregroundStyle(.white)
                    .padding(.horizontal, 48).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.8)))
                    .opacity(a ? 1 : 0).padding(.bottom, 60)
            }
        }
        .onAppear { withAnimation(.easeInOut(duration: 1.2)) { a = true } }
    }
}

// MARK: - Pick (shows saved books + demos)
struct PickScreen: View {
    let demos: [Demo]
    @ObservedObject var repo: Repository
    let onMemory: () -> Void
    let onPick: (Book) -> Void
    @State private var si: Int?
    var body: some View {
        PaperBg {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)
                Text("选择或创建回忆录").font(.system(.title2, design: .serif)).fontWeight(.medium).padding(.bottom, 32)
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(repo.books.enumerated()), id: \.offset) { i, b in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(b.title).font(.system(.body, design: .serif)).fontWeight(.medium)
                                Text("\(b.memories.count) 段回忆").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(si == i ? Color.accentColor : .clear, lineWidth: 2)))
                            .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { si = i } }
                        }
                        ForEach(Array(demos.enumerated()), id: \.offset) { i, d in
                            let idx = repo.books.count + i
                            VStack(alignment: .leading, spacing: 4) {
                                Text(d.title).font(.system(.body, design: .serif)).fontWeight(.medium)
                                Text(d.desc).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(si == idx ? Color.accentColor : .clear, lineWidth: 2)))
                            .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { si = idx } }
                        }
                    }.padding(.horizontal, 32)
                }
                Button("+ 添加回忆") { onMemory() }
                    .font(.system(.body, design: .serif)).foregroundStyle(.primary.opacity(0.7)).padding(.vertical, 8)
                Button(si != nil ? "开始生成" : "请先选择一个故事") {
                    if let i = si {
                        if i < repo.books.count {
                            let b = repo.books[i]
                            onPick(StoryBuilder.build(title: b.title, subtitle: "", from: b.memories))
                        } else {
                            onPick(demos[i - repo.books.count].build())
                        }
                    }
                }
                .font(.system(.body, design: .serif)).foregroundStyle(.white)
                .padding(.horizontal, 40).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(si == nil ? 0.3 : 0.8)))
                .disabled(si == nil).padding(.vertical, 24)
                Spacer().frame(height: 40)
            }
        }
    }
}

// MARK: - Memory Input
struct MemoryScreen: View {
    @ObservedObject var repo: Repository
    let onDone: () -> Void
    @State private var textInput = ""
    @State private var titleInput = ""
    @State private var items: [MemoryItem] = []
    var body: some View {
        PaperBg {
            VStack(spacing: 0) {
                HStack {
                    Button("取消") { onDone() }.padding()
                    Spacer()
                    Text("添加回忆").font(.headline)
                    Spacer()
                    Button("完成") {
                        if !items.isEmpty {
                            let t = titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "回信" : titleInput
                            repo.createBook(title: t, memories: items)
                            onDone()
                        }
                    }.padding().disabled(items.isEmpty)
                }
                ScrollView {
                    VStack(spacing: 16) {
                        TextField("给这本回忆录取个名字", text: $titleInput).font(.system(.title3, design: .serif)).padding(.horizontal)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("粘贴聊天内容").font(.caption).foregroundStyle(.secondary)
                            TextEditor(text: $textInput).frame(minHeight: 120).padding(8).background(RoundedRectangle(cornerRadius: 8).fill(.regularMaterial)).scrollContentBackground(.hidden)
                            Button("添加这段聊天") {
                                let t = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !t.isEmpty { items.append(MemoryItem(content: t, date: Date())); textInput = "" }
                            }.font(.caption).foregroundStyle(.blue).disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }.padding(.horizontal)
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("已添加 \(items.count) 段回忆").font(.caption).foregroundStyle(.secondary)
                                ForEach(Array(items.enumerated()), id: \.offset) { i, m in
                                    HStack {
                                        Text(m.content.prefix(40)).font(.caption).lineLimit(1)
                                        Spacer()
                                        Button { items.remove(at: i) } label: { Image(systemName: "trash").font(.caption).foregroundStyle(.red) }
                                    }.padding(8).background(RoundedRectangle(cornerRadius: 6).fill(.regularMaterial))
                                }
                            }.padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Gen
struct GenScreen: View {
    let done: () -> Void
    @State private var step = 0; @State private var o = 0.0
    let st = ["正在翻阅聊天记录……","正在寻找重要时刻……","正在整理回忆……","正在装订故事……","快完成了……"]
    var body: some View {
        PaperBg {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "book.pages").font(.system(size: 56)).foregroundStyle(.secondary.opacity(0.4)).scaleEffect(o)
                Text(st[min(step, st.count - 1)]).font(.system(.body, design: .serif)).foregroundStyle(.secondary).opacity(o)
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) { o = 1 }
            Task { for i in 0 ..< st.count { step = i; try? await Task.sleep(for: .seconds(1)) }; done() }
        }
    }
}

// MARK: - Reader
struct ReaderScreen: View {
    let book: Book
    let back: () -> Void
    @State private var idx = 0
    @Environment(\.colorScheme) var cs
    var body: some View {
        let bg = cs == .dark ? Color(red: 0.12, green: 0.11, blue: 0.10) : Color(red: 0.96, green: 0.94, blue: 0.90)
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { back() } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.secondary.opacity(0.5)).padding(12) }
                    Spacer()
                }.padding(.top, 8)
                TabView(selection: $idx) {
                    CoverCard(title: book.title, sub: book.subtitle).tag(0)
                    ForEach(Array(book.chapters.enumerated()), id: \.offset) { ci, ch in
                        ForEach(Array(ch.pages.enumerated()), id: \.offset) { pi, pg in
                            PageCard(text: pg).tag(1 + ci * 100 + pi)
                        }
                    }
                    EndCard().tag(9999)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }
}
struct CoverCard: View {
    let title: String; let sub: String
    @State private var a = false
    @Environment(\.colorScheme) var cs
    var body: some View {
        let bg = cs == .dark ? Color(red: 0.12, green: 0.11, blue: 0.10) : Color(red: 0.96, green: 0.94, blue: 0.90)
        ZStack { bg.ignoresSafeArea(); VStack(spacing: 24) {
            Spacer(); Text(title).font(.system(.largeTitle, design: .serif)).fontWeight(.medium).multilineTextAlignment(.center)
            Text(sub).font(.system(.body, design: .serif)).foregroundStyle(.secondary)
            Spacer(); Text("一本聊天回忆录").font(.system(.caption, design: .serif)).foregroundStyle(.secondary.opacity(0.5)).padding(.bottom, 40)
        }.padding(32).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration: 0.8)) { a = true } } }
    }
}
struct PageCard: View {
    let text: String
    @State private var a = false
    @Environment(\.colorScheme) var cs
    var body: some View {
        let bg = cs == .dark ? Color(red: 0.12, green: 0.11, blue: 0.10) : Color(red: 0.96, green: 0.94, blue: 0.90)
        ZStack { bg.ignoresSafeArea(); VStack(alignment: .leading, spacing: 20) {
            Spacer(); Text(text).font(.system(.title3, design: .serif)).lineSpacing(8); Spacer()
        }.padding(32).frame(maxWidth: .infinity).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration: 0.5)) { a = true } } }
    }
}
struct EndCard: View {
    @State private var a = false
    @Environment(\.colorScheme) var cs
    var body: some View {
        let bg = cs == .dark ? Color(red: 0.12, green: 0.11, blue: 0.10) : Color(red: 0.96, green: 0.94, blue: 0.90)
        ZStack { bg.ignoresSafeArea(); VStack(spacing: 32) {
            Spacer(); Rectangle().fill(Color.primary.opacity(0.12)).frame(width: 40, height: 1)
            Text("这些聊天记录").font(.system(.title2, design: .serif)).foregroundStyle(.primary.opacity(0.7))
            Text("就是你们的故事。").font(.system(.title3, design: .serif)).foregroundStyle(.secondary)
            Spacer()
        }.frame(maxWidth: .infinity).multilineTextAlignment(.center).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration: 0.8)) { a = true } } }
    }
}
