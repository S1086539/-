import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(TodoCalendarApp());
}

class TodoCalendarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '待辦事項日曆',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 當前頁面索引
  List<Map<String, dynamic>> _tasks = []; // 存放待辦事項的清單

  // 新增待辦事項
  void _addTask(Map<String, dynamic> task) {
    setState(() {
      _tasks.add({...task, 'isCompleted': false, 'duration': 0});
    });
  }

  // 更新計時器結果
  void _updateTaskDuration(Map<String, dynamic> task, int duration) {
    setState(() {
      task['duration'] = duration;
    });
  }

  // 標記任務為完成
  void _markTaskCompleted(Map<String, dynamic> task) {
    setState(() {
      task['isCompleted'] = true;
    });
  }

  // 切換頁面
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 過濾尚未完成的待辦事項
    final activeTasks = _tasks.where((task) => !task['isCompleted']).toList();

    final List<Widget> _pages = [
      HomePage(
        onAddTask: _addTask,
        tasks: activeTasks, // 傳遞尚未完成的任務
        onCompleteTask: _markTaskCompleted, // 傳遞完成任務的回調
      ),
      CalendarPage(
        tasks: _tasks,
        onTaskTimer: _updateTaskDuration,
        onTaskComplete: _markTaskCompleted,
      ),
    ];

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '主頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '月曆',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function onAddTask; // 新增任務的回調
  final List<Map<String, dynamic>> tasks; // 尚未完成的任務
  final Function onCompleteTask; // 標記完成任務的回調

  HomePage({
    required this.onAddTask,
    required this.tasks,
    required this.onCompleteTask,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _description = ''; // 用來存儲待辦事項的描述
  DateTime _selectedDate = DateTime.now(); // 用來存儲選擇的日期

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主頁'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '事件描述',
                hintText: '描述你的待辦事項',
              ),
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('選擇日期: ${_selectedDate.toLocal()}'.split(' ')[0]),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: const Text('選擇日期'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onAddTask({
                  'description': _description,
                  'date': _selectedDate,
                }); // 傳遞新增的任務
                setState(() {
                  _description = ''; // 清空描述
                });
              },
              child: const Text('新增'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.tasks.length,
                itemBuilder: (context, index) {
                  final task = widget.tasks[index];
                  return ListTile(
                    title: Text(task['description']),
                    subtitle: Text('日期: ${task['date'].toLocal()}'.split(' ')[0]),
                    trailing: Checkbox(
                      value: task['isCompleted'],
                      onChanged: (value) {
                        if (value == true) {
                          widget.onCompleteTask(task); // 標記任務為完成
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarPage extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final Function(Map<String, dynamic>, int) onTaskTimer;
  final Function(Map<String, dynamic>) onTaskComplete;

  CalendarPage({
    required this.tasks,
    required this.onTaskTimer,
    required this.onTaskComplete,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: DateTime.now(),
      eventLoader: (day) {
        return tasks
            .where((task) =>
        task['date'].year == day.year &&
            task['date'].month == day.month &&
            task['date'].day == day.day)
            .toList();
      },
      calendarStyle: const CalendarStyle(
        markerDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        final selectedTasks = tasks
            .where((task) =>
        task['date'].year == selectedDay.year &&
            task['date'].month == selectedDay.month &&
            task['date'].day == selectedDay.day)
            .toList();

        if (selectedTasks.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('事件列表'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: selectedTasks.map((task) {
                    return ListTile(
                      title: Text(task['description']),
                      subtitle: task['duration'] > 0
                          ? Text('耗時: ${task['duration']} 秒')
                          : null,
                      trailing: task['isCompleted']
                          ? const Icon(Icons.check, color: Colors.green)
                          : IconButton(
                        icon: const Icon(Icons.timer),
                        onPressed: () {
                          Navigator.pop(context);
                          _startTaskTimer(context, task);
                        },
                      ),
                    );
                  }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('關閉'),
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }
  // 啟動計時器
  void _startTaskTimer(BuildContext context, Map<String, dynamic> task) {
    int seconds = 0; // 初始化秒數
    Timer? timer; // 用於控制計時器

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 初始化計時器，並確保只啟動一次
            timer ??= Timer.periodic(Duration(seconds: 1), (t) {
              setState(() {
                seconds++; // 每秒更新計時
              });
            });

            return AlertDialog(
              title: Text('計時中: ${task['description']}'),
              content: Text('計時: $seconds 秒'),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel(); // 停止計時器
                    onTaskTimer(task, seconds); // 更新任務耗時到全域資料
                    Navigator.pop(context); // 關閉對話框
                  },
                  child: const Text('停止計時'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      timer?.cancel(); // 確保在對話框關閉時停止計時器
    });
  }
}
