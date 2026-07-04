import SwiftUI; import UIKit; import ObjectiveC

private var _pk: UInt8 = 0
extension UIViewController { var pi: Int { get { objc_getAssociatedObject(self, &_pk) as? Int ?? 0 } set { objc_setAssociatedObject(self, &_pk, newValue, .OBJC_ASSOCIATION_RETAIN) } } }

struct Book: Identifiable { let id = UUID().uuidString; let title: String; let subtitle: String; let chapters: [Chap] }
struct Chap: Identifiable { let id = UUID().uuidString; let title: String; let pages: [String] }
struct Demo: Identifiable { let id: String; let title: String; let subtitle: String; let desc: String
    func build() -> Book {
        let chaps: [Chap]
        switch id {
        case "alice": chaps = [Chap(title:"我们的故事",pages:["2023年3月15日\n第一条消息。","从你好到晚安\n慢慢地，每天都是这样。","2024年春节\n互相发了很长的祝福。","那年夏天聊得最多\n经常聊到凌晨。","到今年已经两年多了\n不知不觉。"])]
        case "bob":   chaps = [Chap(title:"深夜对话",pages:["2021年6月\n深夜第一次长聊。","经常凌晨一两点\n聊工作、人生。","三年了\n谢谢你听我说那么多。"])]
        case "family": chaps = [Chap(title:"我们的家",pages:["2020年\n我们家的群聊。","每次节日\n妈妈都问：回来吃饭吗？","1800天了\n家永远是最温暖的地方。"])]
        default: chaps = []
        }
        return Book(title:title, subtitle:subtitle, chapters:chaps)
    }
    static let alice  = Demo(id:"alice",title:"Alice 与我",subtitle:"温暖日常",desc:"两年半的聊天。")
    static let bob    = Demo(id:"bob",title:"Bob 与我",subtitle:"深夜对话",desc:"三年深夜聊了无数次。")
    static let family = Demo(id:"family",title:"我们的家",subtitle:"群聊记忆",desc:"一家四口的群聊。")
}

enum AppPhase: Equatable { case welcome; case pick; case gen; case reader }
@main struct ChatMemoirApp: App {
    @State private var phase: AppPhase = .welcome
    @State private var book: Book? = nil
    let demos: [Demo] = [.alice, .bob, .family]
    var body: some Scene { WindowGroup {
        ZStack { switch phase {
        case .welcome: WelcomeView { phase = .pick }
        case .pick:    PickView(demos: demos) { b in book = b; phase = .gen }
        case .gen:     GenView { phase = .reader }
        case .reader:  if let b = book { ReaderView(book: b) { phase = .pick } }
        } }
        .animation(.easeInOut(duration: 0.6), value: phase)
    } }
}

struct PaperBg<Content: View>: View { @Environment(\.colorScheme) var cs; let content: Content
    init(@ViewBuilder _ c: () -> Content) { self.content = c() }
    var body: some View { ZStack { (cs == .dark ? Color(red:0.12,green:0.11,blue:0.10) : Color(red:0.96,green:0.94,blue:0.90)).ignoresSafeArea(); content } }
}

struct WelcomeView: View {
    let onStart: () -> Void
    @State private var a = false
    var body: some View {
        PaperBg {
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) { Text("ChatMemoir").font(.system(.largeTitle,design:.serif)).fontWeight(.medium).tracking(3).foregroundStyle(.primary.opacity(0.85)); Text("把值得珍藏的聊天，\n做成一本真正属于你的书。").font(.system(.body,design:.serif)).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(6) }
                .opacity(a ? 1 : 0).offset(y: a ? 0 : 20)
                Spacer()
                Button("开始制作"){onStart()}.font(.system(.body,design:.serif)).foregroundStyle(.white).padding(.horizontal,48).padding(.vertical,14).background(RoundedRectangle(cornerRadius:10).fill(Color.primary.opacity(0.8))).opacity(a ? 1 : 0).padding(.bottom,60)
            }
        }
        .onAppear { withAnimation(.easeInOut(duration: 1.2)) { a = true } }
    }
}

struct PickView: View {
    let demos: [Demo]
    let onPick: (Book) -> Void
    @State private var si: Int?
    var body: some View {
        PaperBg {
            VStack(spacing: 0) {
                Spacer().frame(height:60); Text("选择一个故事").font(.system(.title2,design:.serif)).fontWeight(.medium).padding(.bottom,32)
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(demos.enumerated()), id: \.offset) { i, d in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(d.title).font(.system(.body,design:.serif)).fontWeight(.medium)
                                Text(d.desc).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius:12).fill(.regularMaterial).overlay(RoundedRectangle(cornerRadius:12).stroke(si==i ? Color.accentColor:.clear,lineWidth:2)))
                            .onTapGesture { withAnimation(.easeInOut(duration:0.3)) { si = i } }
                        }
                    }.padding(.horizontal, 32)
                }
                Button(si != nil ? "开始生成" : "请先选择一个故事") {
                    if let i = si { onPick(demos[i].build()) }
                }
                .font(.system(.body,design:.serif)).foregroundStyle(.white).padding(.horizontal,40).padding(.vertical,14)
                .background(RoundedRectangle(cornerRadius:10).fill(Color.primary.opacity(si == nil ? 0.3 : 0.8)))
                .disabled(si == nil).padding(.vertical, 24)
                Spacer().frame(height: 40)
            }
        }
    }
}

struct GenView: View {
    let done: () -> Void
    @State private var step = 0
    @State private var o = 0.0
    let st = ["正在翻阅聊天记录……","正在寻找重要时刻……","正在整理回忆……","正在装订故事……","快完成了……"]
    var body: some View {
        PaperBg {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName:"book.pages").font(.system(size:56)).foregroundStyle(.secondary.opacity(0.4)).scaleEffect(o)
                Text(st[min(step,st.count-1)]).font(.system(.body,design:.serif)).foregroundStyle(.secondary).opacity(o).animation(.easeInOut(duration:0.3),value:step)
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration:1.0)) { o = 1 }
            Task {
                for i in 0..<st.count { step = i; try? await Task.sleep(for: .seconds(1)) }
                done()
            }
        }
    }
}

struct ReaderView: View {
    let book: Book
    let back: () -> Void
    @State private var idx = 0
    @Environment(\.colorScheme) var cs
    private var pages: [AnyView] {
        var p: [AnyView] = [AnyView(CoverCard(title: book.title, sub: book.subtitle))]
        for ch in book.chapters { for pg in ch.pages { p.append(AnyView(PageCard(text: pg, chapter: ch.title))) } }
        p.append(AnyView(EndCard()))
        return p
    }
    var body: some View {
        let bg = cs == .dark ? Color(red:0.12,green:0.11,blue:0.10) : Color(red:0.96,green:0.94,blue:0.90)
        ZStack { bg.ignoresSafeArea()
            if !pages.isEmpty { PageCurlVC(pages: pages, cp: $idx) }
            VStack { HStack { Button{back()}label:{Image(systemName:"xmark.circle.fill").font(.title2).foregroundStyle(.secondary.opacity(0.5)).padding(12)}; Spacer() }.padding(.top,8); Spacer() }
        }
    }
}

struct PageCurlVC: UIViewControllerRepresentable { let pages: [AnyView]; @Binding var cp: Int
    func makeCoordinator() -> C { C(self) }
    func makeUIViewController(context: Context) -> UIPageViewController { let pvc = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: [.spineLocation: UIPageViewController.SpineLocation.mid.rawValue]); pvc.dataSource = context.coordinator; pvc.delegate = context.coordinator; pvc.isDoubleSided = true; if let f = host(0) { pvc.setViewControllers([f], direction: .forward, animated: false) }; return pvc }
    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {}
    func host(_ i: Int) -> UIHostingController<AnyView>? { guard i >= 0, i < pages.count else { return nil }; let h = UIHostingController(rootView: pages[i]); h.view.backgroundColor = UIColor(red:0.96,green:0.94,blue:0.90,alpha:1); h.pi = i; return h }
    class C: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate { let p: PageCurlVC; init(_ p: PageCurlVC) { self.p = p }
        func pageViewController(_ pvc: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? { p.host(vc.pi - 1) }
        func pageViewController(_ pvc: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? { p.host(vc.pi + 1) }
        func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) { guard completed, let vc = pvc.viewControllers?.first else { return }; p.cp = vc.pi }
    }
}


struct CoverCard: View {
    let title: String; let sub: String; @State private var a = false; @Environment(\.colorScheme) var cs
    var body: some View {
        let bg = cs == .dark ? Color(red:0.12,green:0.11,blue:0.10) : Color(red:0.96,green:0.94,blue:0.90)
        ZStack { bg.ignoresSafeArea()
        VStack(spacing: 24) {
            Spacer()
            Text(title).font(.system(.largeTitle,design:.serif)).fontWeight(.medium).multilineTextAlignment(.center)
            Text(sub).font(.system(.body,design:.serif)).foregroundStyle(.secondary)
            Spacer()
            Text("一本聊天回忆录").font(.system(.caption,design:.serif)).foregroundStyle(.secondary.opacity(0.5)).padding(.bottom,40)
        }.padding(32).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration:0.8)) { a = true } }
        }
    }
}

struct PageCard: View {
    let text: String; let chapter: String; @State private var a = false; @Environment(\.colorScheme) var cs
    var body: some View {
        let bg = cs == .dark ? Color(red:0.12,green:0.11,blue:0.10) : Color(red:0.96,green:0.94,blue:0.90)
        ZStack { bg.ignoresSafeArea()
        VStack(alignment:.leading, spacing: 20) {
            Text(chapter).font(.system(.caption,design:.serif)).foregroundStyle(.secondary.opacity(0.6)).textCase(.uppercase).tracking(2)
            Spacer()
            Text(text).font(.system(.title3,design:.serif)).lineSpacing(8)
            Spacer()
        }.padding(32).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration:0.5)) { a = true } }
        }
    }
}

struct EndCard: View {
    @State private var a = false; @Environment(\.colorScheme) var cs
    var body: some View {
        let bg = cs == .dark ? Color(red:0.12,green:0.11,blue:0.10) : Color(red:0.96,green:0.94,blue:0.90)
        ZStack { bg.ignoresSafeArea()
        VStack(spacing: 32) {
            Spacer()
            Rectangle().fill(Color.primary.opacity(0.12)).frame(width:40,height:1)
            Text("这些聊天记录").font(.system(.title2,design:.serif)).foregroundStyle(.primary.opacity(0.7))
            Text("就是你们的故事。").font(.system(.title3,design:.serif)).foregroundStyle(.secondary)
            Spacer()
        }.frame(maxWidth:.infinity).multilineTextAlignment(.center).opacity(a ? 1 : 0).onAppear { withAnimation(.easeIn(duration:0.8)) { a = true } }
        }
    }
}