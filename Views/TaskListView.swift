//
//  TaskListView.swift
//  TaskJarvis
//
//  Created by Charan Tatineni on 9/13/25.
//
import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingAddTask = false
    @State private var editingTask: Task? = nil
    @State private var selectedTab = 0
    
    enum TaskFilter {
        case all
        case today
        case daily
        case completed
        case pending
        case futureStart
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                
                taskListView(filter: .today)
                    .tabItem {
                        Label("Today", systemImage: "calendar")
                    }
                    .tag(0)
                
                taskListView(filter: .daily)
                    .tabItem {
                        Label("Daily", systemImage: "repeat")
                    }
                    .tag(1)
                
                taskListView(filter: .all)
                    .tabItem {
                        Label("Reminders", systemImage: "bell")
                    }
                    .tag(2)
                
                
            }
            
            // Floating Action Button above tab bar
            Button(action: { showingAddTask.toggle() }) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 70) // move above tab bar
            .sheet(isPresented: $showingAddTask) {
                EnhancedAddTaskView(viewModel: viewModel)
            }
            .sheet(item: $editingTask) { task in
                EnhancedAddTaskView(viewModel: viewModel, editTask: task)
            }
        }
    }
    
    private func taskListView(filter: TaskFilter) -> some View {
        VStack {
            // Existing task list
            List {
                ForEach(viewModel.filteredTasks(filter: filter)) { task in
                    TaskRow(task: task, onToggle: {
                        viewModel.toggleTask(task)
                    })
                    .onTapGesture { editingTask = task }
                    
                    // Card-like row styling
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    // Swipe to delete
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteTask(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)   // keep dark background showing through
            .background(Color(.systemBackground))
        }
    }
}

