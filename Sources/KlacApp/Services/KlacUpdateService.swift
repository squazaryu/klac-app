import Foundation

struct GitHubRelease: Decodable {
    struct Asset: Decodable {
        let name: String
        let browser_download_url: String
    }

    let tag_name: String
    let html_url: String
    let assets: [Asset]
}

struct KlacUpdateService {
    let owner: String
    let repository: String
    let session: URLSession

    init(owner: String, repository: String, session: URLSession = .shared) {
        self.owner = owner
        self.repository = repository
        self.session = session
    }

    func fetchLatestRelease() async throws -> GitHubRelease {
        let endpoint = "https://api.github.com/repos/\(owner)/\(repository)/releases/latest"
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "KlacUpdate", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Некорректный URL обновлений"])
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("KlacAppUpdater", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw NSError(domain: "KlacUpdate", code: 1002, userInfo: [NSLocalizedDescriptionKey: "GitHub API вернул ошибку"])
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}
