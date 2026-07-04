import SwiftUI; import UIKit; import ObjectiveC; import Foundation; import TimelineEngine; import StoryEngine; import PresentationEngine; import ChatImportKit

// MARK: - Page Index via ObjC
private var _k: UInt8 = 0
extension UIViewController {
    var pi: Int { get { objc_getAssociatedObject(self, &_k) as? Int ?? 0 } set { objc_setAssociatedObject(self, &_k, newValue, .OBJC_ASSOCIATION_RETAIN) } }
}

// MARK: - App
@main struct ChatMemoirApp: App { var body: some Scene { WindowGroup { RootView() } } }

struct RootView: View { @State private var path: [String] = []; @State private var doc: RenderDocument?; let samples: [SDemo] = [.alice, .bob, .family]
    var body: some View { NavigationStack(path: $path) {
        WelcomeScreen { path.append("import") }
        .navigationDestination(for: String.self) { d in
            if d == "import" { ImportScreen(samples: samples, doc: $doc, path: $path).navigationBarHidden(true) }
            else if d == "gen" { GenScreen(doc: $doc, path: $path).navigationBarHidden(true) }
            else if d == "reader", let d = doc { ReaderScreen(doc: d, path: $path).navigationBarHidden(true) }
        }
    } }
}

// MARK: - Welcome
struct WelcomeScreen: View { let onStart: () -> Void; @State private var a = false; @Environment(\.colorScheme) private var cs
    var body: some View { let bg = cs == .dark ? Color(red: 0.12, green: 0.11, blue: 0.10) : Color(red: 0.96, green: 0.94, blue: 0.90)
        ZStack { bg.ignoresSafeArea(); VStack(spacing: 0) {
            Spacer(); VStack(spacing: 16) { Text("ChatMemoir").font(.system(.largeTitle, design: .serif)).fontWeight(.medium).tracking(3).foregroundStyle(.primary.opacity(0.85)); Text("把值得珍藏的聊天，\n做成一本真正属于你的书。").font(.system(.body, design: .serif)).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(6) }.opacity(a ? 1 : 0).offset(y: a ? 0 : 20)
            Spacer(); Button("开始制作") { onStart() }.font(.system(.body, design: .serif)).foregroundStyle(.white).padding(.horizontal, 48).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.8))).opacity(a ? 1 : 0).padding(.bottom, 60)
        }.onAppear { withAnimation(.easeInOut(duration: 1.2)) { a = true } } }
    }
}

// MARK: - Import
struct ImportScreen: View { let samples: [SDemo]; @Binding var doc: RenderDocument?; @Binding var path: [String]; @State private var si: Int?
    var body: some View { ZStack { Color(red: 0.96, green: 0.94, blue: 0.90).ignoresSafeArea(); VStack(spacing: 0) {
        Spacer().frame(height: 60); Text("选择一个故事").font(.system(.title2, design: .serif)).fontWeight(.medium).padding(.bottom, 32)
        ScrollView { VStack(spacing: 16) { ForEach(Array(samples.enumerated()), id: \.offset) { i, s in
            VStack(alignment: .leading, spacing: 4) { Text(s.title).font(.system(.body, design: .serif)).fontWeight(.medium); Text(s.desc).font(.caption).foregroundStyle(.secondary) }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading).background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial).overlay(RoundedRectangle(cornerRadius: 12).stroke(si == i ? Color.accentColor : .clear, lineWidth: 2)))
            .onTapGesture { withAnimation(.easeInOut(duration: 0.3)) { si = i } }
        } }.padding(.horizontal, 32) }
        Button(si != nil ? "开始生成" : "请先选择一个故事") { if let i = si { Task { doc = await samples[i].generate(); path.append("gen") } } }
        .font(.system(.body, design: .serif)).foregroundStyle(.white).padding(.horizontal, 40).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(si == nil ? 0.3 : 0.8))).disabled(si == nil).padding(.vertical, 24)
        Spacer().frame(height: 40)
    } } }
}

// MARK: - Generating
struct GenScreen: View { @Binding var doc: RenderDocument?; @Binding var path: [String]; @State private var step = 0; @State private var o = 0.0; let steps = ["正在翻阅聊天记录……", "正在寻找重要时刻……", "正在整理回忆……", "正在装订故事……", "快完成了……"]
    var body: some View { ZStack { Color(red: 0.96, green: 0.94, blue: 0.90).ignoresSafeArea(); VStack(spacing: 32) {
        Spacer(); Image(systemName: "book.pages").font(.system(size: 56)).foregroundStyle(.secondary.opacity(0.4)).scaleEffect(o)
        Text(steps[min(step, steps.count - 1)]).font(.system(.body, design: .serif)).foregroundStyle(.secondary).opacity(o).animation(.easeInOut(duration: 0.3), value: step)
        Spacer()
    }.onAppear { withAnimation(.easeInOut(duration: 1.0)) { o = 1 }; Task { for i in 0 ..< steps.count { step = i; try? await Task.sleep(for: .seconds(1)) }; path.removeLast(); path.append("reader") } } } }
}

// MARK: - Reader with Page Curl
struct ReaderScreen: View { let doc: RenderDocument; @Binding var path: [String]; @State private var cp = 0; @Environment(\.colorScheme) private var cs
    private var pages: [AnyView] {
        var p: [AnyView] = [AnyView(CoverPage(title: doc.title, subtitle: doc.subtitle))]
        for page in doc.pages where page.pageType != .divider && page.pageType != .cover {
            for block in page.blocks {
                if case .paragraph(let pb) = block { p.append(AnyView(BlockPage(text: pb.rewrittenText ?? pb.rawText))) }
                else if case .title(let tb) = block { p.append(AnyView(TitlePage(text: tb.rewrittenText ?? tb.rawText))) }
                else if case .statistic(let sb) = block { p.append(AnyView(StatPage(value: sb.value, label: sb.label, unit: sb.unit))) }
                else if case .quote(let qb) = block { p.append(AnyView(QuotePage(text: qb.rewrittenText ?? qb.rawText, attr: qb.attribution))) }
                else if case .milestone(let mb) = block { p.append(AnyView(BlockPage(text: mb.rewrittenText ?? mb.rawText))) }
            }
        }
        p.append(AnyView(EndPage())); return p
    }
    var body: some View { let bg = cs == .dark ? Color(red: 0.12, green: 0.11, blue: 0.10) : Color(red: 0.96, green: 0.94, blue: 0.90)
        ZStack { bg.ignoresSafeArea(); if !pages.isEmpty { PageCurlVC(pages: pages, cp: $cp).ignoresSafeArea() }
            VStack { HStack { Button { path.removeLast() } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.secondary.opacity(0.5)).padding(12) }; Spacer(); if !pages.isEmpty { Text("\(cp + 1)/\(pages.count)").font(.caption).foregroundStyle(.secondary.opacity(0.5)).monospacedDigit().padding(.trailing, 12) } }.padding(.top, 8); Spacer() }
        }
    }
}

// MARK: - UIPageViewController Wrapper
struct PageCurlVC: UIViewControllerRepresentable { let pages: [AnyView]; @Binding var cp: Int
    func makeCoordinator() -> C { C(self) }
    func makeUIViewController(context: Context) -> UIPageViewController { let pvc = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: [.spineLocation: UIPageViewController.SpineLocation.mid.rawValue]); pvc.dataSource = context.coordinator; pvc.delegate = context.coordinator; pvc.isDoubleSided = true; if let f = host(0) { pvc.setViewControllers([f], direction: .forward, animated: false) }; return pvc }
    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {}
    func host(_ i: Int) -> UIHostingController<AnyView>? { guard i >= 0, i < pages.count else { return nil }; let h = UIHostingController(rootView: pages[i]); h.view.backgroundColor = UIColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1); h.pi = i; return h }
    class C: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate { let p: PageCurlVC; init(_ p: PageCurlVC) { self.p = p }
        func pageViewController(_ pvc: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? { p.host(vc.pi - 1) }
        func pageViewController(_ pvc: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? { p.host(vc.pi + 1) }
        func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) { guard completed, let vc = pvc.viewControllers?.first else { return }; p.cp = vc.pi }
    }
}

// MARK: - Pages
struct CoverPage: View { let title: String; let subtitle: String; @State private var a = false
    var body: some View { VStack(spacing: 24) { Spacer(); Text(title).font(.system(.largeTitle, design: .serif)).fontWeight(.medium).multilineTextAlignment(.center); Text(subtitle).font(.system(.body, design: .serif)).foregroundStyle(.secondary); Spacer(); Text("一本聊天回忆录").font(.system(.caption, design: .serif)).foregroundStyle(.secondary.opacity(0.5)).padding(.bottom, 40) }.padding(32).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration: 0.8)) { a = true } } }
}
struct BlockPage: View { let text: String; @State private var a = false
    var body: some View { VStack(alignment: .leading, spacing: 20) { Spacer(); Text(text).font(.system(.title3, design: .serif)).lineSpacing(8).foregroundStyle(.primary); Spacer() }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration: 0.5)) { a = true } } }
}
struct EndPage: View { @State private var a = false
    var body: some View { VStack(spacing: 32) { Spacer(); Rectangle().fill(Color.primary.opacity(0.12)).frame(width: 40, height: 1); Text("这些聊天记录").font(.system(.title2, design: .serif)).foregroundStyle(.primary.opacity(0.7)); Text("就是你们的故事。").font(.system(.title3, design: .serif)).foregroundStyle(.secondary); Spacer() }.frame(maxWidth: .infinity).multilineTextAlignment(.center).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration: 0.8)) { a = true } } }
}


struct TitlePage: View { let text: String; @State private var a = false
    var body: some View { VStack(spacing: 24) { Spacer(); Text(text).font(.system(.largeTitle, design: .serif)).fontWeight(.medium).multilineTextAlignment(.center); Spacer() }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration: 0.5)) { a = true } } }
}
struct StatPage: View { let value: String; let label: String; let unit: String?; @State private var a = false
    var body: some View { VStack(spacing: 16) { Spacer(); VStack(spacing: 4) { HStack(alignment: .lastTextBaseline, spacing: 2) { Text(value).font(.system(size: 56, weight: .light, design: .serif)); if let u = unit { Text(u).font(.system(.body, design: .serif)).foregroundStyle(.secondary) } }; Text(label).font(.caption).foregroundStyle(.secondary) }.padding(24).background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial)); Spacer() }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration: 0.5)) { a = true } } }
}
struct QuotePage: View { let text: String; let attr: String?; @State private var a = false
    var body: some View { VStack(spacing: 24) { Spacer(); HStack(spacing: 0) { Rectangle().fill(Color.primary.opacity(0.15)).frame(width: 3); VStack(alignment: .leading, spacing: 8) { Text(text).font(.system(.title3, design: .serif)).italic().foregroundStyle(.primary.opacity(0.8)); if let at = attr { Text("-- \(at)").font(.caption).foregroundStyle(.secondary) } }.padding(.leading, 16) }.padding(.horizontal, 4); Spacer() }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration: 0.5)) { a = true } } }
}

// MARK: - Sample Data + Pipeline
struct SDemo: Identifiable { let id: String; let title: String; let subtitle: String; let desc: String
    func generate() async -> RenderDocument { let db = SDemo.buildDB(id: id, title: title); let tl = TimelineEngine.generate(from: db); let story = StoryEngine.generate(from: tl); return PresentationEngine.render(story: story, theme: .warm) }
    static let alice = SDemo(id: "alice", title: "Alice 与我", subtitle: "2023 - 2025", desc: "两年半的聊天。")
    static let bob   = SDemo(id: "bob", title: "Bob 与我", subtitle: "2021 - 2024", desc: "三年深夜聊了无数次。")
    static let family = SDemo(id: "family", title: "我们的家", subtitle: "2020 - 2024", desc: "一家四口的群聊。")
    static func buildDB(id: String, title _: String) -> ChatDatabase { let o = Participant(id: "me", displayName: "我")
        let ms: [Message]; let name: String; let baseY: Int
        switch id {
        case "alice": name = "Alice"; baseY = 2023; ms = SDemo.makeMs(o: o, f: Participant(id: "a", displayName: "Alice"), baseY: baseY, baseM: 3, days: 900, hourMin: 7, hourMax: 23, msgs: ["早安☀️", "晚安🌙", "今天吃什么？", "哈哈哈哈", "想你了", "下班了吗？", "周末去哪？", "好困", "谢谢你", "有你真好"])
        case "bob": name = "Bob"; baseY = 2021; ms = SDemo.makeMs(o: o, f: Participant(id: "b", displayName: "Bob"), baseY: baseY, baseM: 6, days: 1100, hourMin: 20, hourMax: 23, msgs: ["你睡了吗", "我也在想这个", "人生啊", "深夜了", "刚喝完酒", "都会好起来的", "晚安兄弟"])
        case "family": name = "我们的家"; baseY = 2020; let mom = Participant(id: "mom", displayName: "妈妈"); let dad = Participant(id: "dad", displayName: "爸爸"); let sis = Participant(id: "sis", displayName: "妹妹"); let mem = [o, mom, dad, sis]; ms = SDemo.makeGroupMs(members: mem, baseY: baseY, days: 1800, msgs: ["吃饭了吗", "天冷了多穿点", "周末回来吗", "注意身体", "家里都好", "生日快乐🎂", "我们都好"]); let ch = Chat(id: "family", displayName: name, isGroupChat: true, participants: mem, messages: ms, lastMessageAt: ms.last?.timestamp); return ChatDatabase(platform: .wechat, owner: o, chats: [ch])
        default: name = "Alice"; baseY = 2023; ms = []
        }
        let f = Participant(id: id, displayName: name); let ch = Chat(id: id, displayName: name, isGroupChat: false, participants: [o, f], messages: ms, lastMessageAt: ms.last?.timestamp); return ChatDatabase(platform: .wechat, owner: o, chats: [ch])
    }
    static func makeMs(o: Participant, f: Participant, baseY: Int, baseM: Int, days: Int, hourMin: Int, hourMax: Int, msgs: [String]) -> [Message] { var m: [Message] = []; var c = 0; let cal = Calendar.current; let base = cal.date(from: DateComponents(year: baseY, month: baseM, day: 15))!; for day in 0 ..< days { let dt = cal.date(byAdding: .day, value: day, to: base)!; let cnt = (cal.component(.weekday, from: dt) == 1 || cal.component(.weekday, from: dt) == 7) ? Int.random(in: 1 ... 5) : Int.random(in: 2 ... 18); for _ in 0 ..< cnt { c += 1; let sdr = c % 3 == 0 ? o : f; var comps = cal.dateComponents([.year, .month, .day], from: dt); comps.hour = Int.random(in: hourMin ... hourMax); let ts = cal.date(from: comps)!; m.append(Message(id: "\(f.id)\(c)", sender: sdr, timestamp: ts, type: .text, content: msgs.randomElement()!)) } }; return m }
    static func makeGroupMs(members: [Participant], baseY: Int, days: Int, msgs: [String]) -> [Message] { var m: [Message] = []; var c = 0; let cal = Calendar.current; let base = cal.date(from: DateComponents(year: baseY, month: 1, day: 1))!; for day in 0 ..< days { let dt = cal.date(byAdding: .day, value: day, to: base)!; let cnt = Int.random(in: 0 ... 4); for _ in 0 ..< cnt { c += 1; let sdr = members[c % members.count]; var comps = cal.dateComponents([.year, .month, .day], from: dt); comps.hour = Int.random(in: 8 ... 22); let ts = cal.date(from: comps)!; m.append(Message(id: "g\(c)", sender: sdr, timestamp: ts, type: .text, content: msgs.randomElement()!)) } }; return m }
}

func fmt(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy年M月d日"; return f.string(from: d) }
