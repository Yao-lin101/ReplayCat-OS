import SwiftUI
import CoreData

struct LocalTemplatesView: View {
    @EnvironmentObject private var router: NavigationRouter
    @State private var showingLanguageInput = false
    @State private var showingEditSheet = false
    @State private var newLanguage = ""
    @State private var showingDeleteAlert = false
    @State private var languageToDelete: String?
    @State private var templatesByLanguage: [String: [Template]] = [:]
    @State private var languageSections: [LocalLanguageSection] = []
    @State private var searchText = ""
    @State private var sectionToEdit: LocalLanguageSection?
    @State private var refreshTrigger = UUID()
    
    
    var body: some View {
        List {
            ForEach(languageSections, id: \.id) { section in
                languageSectionRow(section)
            }
        }
        .id(refreshTrigger)
        .listStyle(.plain)
        .navigationTitle("本地模板")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // 重置所有状态
                    newLanguage = ""
                    sectionToEdit = nil  // 重置编辑状态
                    showingLanguageInput = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingLanguageInput) {
            addLanguageSectionSheet
        }
        .sheet(isPresented: $showingEditSheet) {
            editLanguageSectionSheet
        }
        .confirmationDialog("所有模板和录音记录都将删除。", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
            Button("删除分区", role: .destructive) {
                if let language = languageToDelete,
                   let section = languageSections.first(where: { $0.name == language }) {
                    deleteLanguageSection(section)
                }
            }
            Button("取消", role: .cancel) {
                languageToDelete = nil
            }
        }
        .onAppear {
            loadLanguageSections()
            refreshTrigger = UUID()
        }
    }
    
    private var addLanguageSectionSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("语言名称", text: $newLanguage)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("添加语言分区")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        newLanguage = ""
                        showingLanguageInput = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        if !newLanguage.isEmpty {
                            addLanguageSection(newLanguage)
                            newLanguage = ""
                            showingLanguageInput = false
                        }
                    }
                    .disabled(newLanguage.isEmpty)
                }
            }
        }
    }
    
    private var editLanguageSectionSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("语言名称", text: $newLanguage)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                
            }
            .navigationTitle("编辑语言分区")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        newLanguage = ""
                        sectionToEdit = nil
                        showingEditSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if !newLanguage.isEmpty, let section = sectionToEdit {
                            updateLanguageSection(section, newName: newLanguage)
                            newLanguage = ""
                            sectionToEdit = nil
                            showingEditSheet = false
                        }
                    }
                    .disabled(newLanguage.isEmpty)
                }
            }
            .onAppear {
                if let section = sectionToEdit {
                    newLanguage = section.name ?? ""
                }
            }
        }
    }
    
    private func languageSectionRow(_ section: LocalLanguageSection) -> some View {
        var totalCount = 0
        let localCount = (section.templates?.count ?? 0)
        let videoCount = (section.videoTemplates?.count ?? 0)
        totalCount = localCount + videoCount
        
        return NavigationLink(value: Route.languageSection(section.name ?? "")) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.name ?? "")
                        .font(.headline)
                    
                    // 显示本地和云端模板数量
                    HStack(spacing: 12) {
                        Label("\(localCount + videoCount)", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 显示总数
                Text("\(totalCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .contentShape(Rectangle())
        }
        .swipeActions(edge: .trailing) {
            Button {
                // 检查该语言分区是否有模板（本地或云端）
                if totalCount > 0 {
                    // 有模板时显示确认对话框
                    languageToDelete = section.name
                    showingDeleteAlert = true
                } else {
                    // 没有模板时直接删除
                    deleteLanguageSection(section)
                }
            } label: {
                Label("删除", systemImage: "trash")
            }
            .tint(.red)
            
            Button {
                sectionToEdit = section
                showingEditSheet = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
    
    private func updateLanguageSection(_ section: LocalLanguageSection, newName: String) {
        do {
            try TemplateStorage.shared.updateLanguageSection(
                id: section.id ?? "", 
                name: newName, 
                cloudSectionId: ""
            )
            loadLanguageSections()
        } catch {
            print("Error updating language section: \(error)")
        }
    }
    
    private func loadLanguageSections() {
        do {
            languageSections = try TemplateStorage.shared.listLanguageSections()
        } catch {
            print("Error loading language sections: \(error)")
            languageSections = []
        }
    }
    
    private func addLanguageSection(_ name: String) {
        do {
            _ = try TemplateStorage.shared.createLanguageSection(name: name, cloudSectionId: "")
            loadLanguageSections()
        } catch {
            print("Error adding language section: \(error)")
        }
    }
    
    private func deleteLanguageSection(_ section: LocalLanguageSection) {
        do {
            try TemplateStorage.shared.deleteLanguageSection(section)
            loadLanguageSections()
            languageToDelete = nil
        } catch {
            print("Error deleting language section: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        LocalTemplatesView()
            .environmentObject(NavigationRouter())
    }
} 
