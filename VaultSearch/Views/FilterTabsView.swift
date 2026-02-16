import SwiftUI

struct FilterTabsView: View {
    @Binding var selected: MediaFilter
    let totalCount: Int
    let imageCnt: Int
    let videoCnt: Int
    let audioCnt: Int

    var body: some View {
        HStack(spacing: 6) {
            filterPill(.all, count: totalCount)
            filterPill(.images, count: imageCnt)
            filterPill(.video, count: videoCnt)
            filterPill(.audio, count: audioCnt)
        }
    }

    private func filterPill(_ filter: MediaFilter, count: Int) -> some View {
        Button {
            selected = filter
        } label: {
            Text("\(filter.rawValue) (\(count))")
                .font(.system(size: 11, weight: selected == filter ? .semibold : .regular))
                .foregroundColor(selected == filter ? Color.white : Color.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    selected == filter
                        ? Color.accentColor.opacity(0.8)
                        : Color(nsColor: .controlBackgroundColor)
                )
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
