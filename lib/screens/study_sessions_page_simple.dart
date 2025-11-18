import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/study_session_service.dart';
import '../services/auth_service.dart';

class StudySessionsPage extends StatefulWidget {
  @override
  _StudySessionsPageState createState() => _StudySessionsPageState();
}

class _StudySessionsPageState extends State<StudySessionsPage> {
  List<StudySession> _sessions = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (_hasMore && !_isLoading) {
        _loadMoreSessions();
      }
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await StudySessionService.instance.getAllStudySessions(
        page: 1,
        limit: 10,
      );

      setState(() {
        if (result['success']) {
          _sessions = result['sessions'];
          // Debug: Print hasJoined status
          for (var session in _sessions) {
            print('Session: ${session.title}, hasJoined: ${session.hasJoined}');
          }
          final pagination = result['pagination'] as StudySessionPagination;
          _hasMore = pagination.hasNext;
          _currentPage = 1;
        } else {
          _error = result['message'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreSessions() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await StudySessionService.instance.getAllStudySessions(
        page: _currentPage + 1,
        limit: 10,
      );

      setState(() {
        if (result['success']) {
          _sessions.addAll(result['sessions']);
          final pagination = result['pagination'] as StudySessionPagination;
          _hasMore = pagination.hasNext;
          _currentPage++;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load more sessions')));
    }
  }

  Future<void> _joinSession(String sessionId) async {
    final result = await StudySessionService.instance.joinStudySession(
      sessionId,
    );
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSessions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _leaveSession(String sessionId) async {
    final result = await StudySessionService.instance.leaveStudySession(
      sessionId,
    );
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left session successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSessions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final result = await StudySessionService.instance.deleteStudySession(
      sessionId,
    );
    if (result['success']) {
      setState(() => _sessions.removeWhere((s) => s.id == sessionId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session deleted!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final subjectController = TextEditingController();
    final linkController = TextEditingController();
    final locationController = TextEditingController();
    final maxController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    String selectedPlatform = 'Zoom';
    String selectedType = 'Online';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.9;

        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[700]!, Colors.blue[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.groups, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Create Study Buddy',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel(
                            'Basic Information',
                            Icons.info_outline,
                          ),
                          SizedBox(height: 12),
                          _buildTextField(
                            controller: titleController,
                            label: 'Title',
                            hint: 'e.g., Calculus Study Group',
                            icon: Icons.title,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: descController,
                            label: 'Description',
                            hint: 'What will you study?',
                            icon: Icons.description,
                            maxLines: 3,
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: subjectController,
                            label: 'Subject',
                            hint: 'e.g., Mathematics',
                            icon: Icons.book,
                          ),
                          SizedBox(height: 24),
                          _buildSectionLabel(
                            'Platform Details',
                            Icons.computer,
                          ),
                          SizedBox(height: 12),
                          _buildDropdown(
                            value: selectedPlatform,
                            label: 'Platform',
                            icon: Icons.video_call,
                            items: [
                              'Zoom',
                              'Google Meet',
                              'Microsoft Teams',
                              'Discord',
                              'Other',
                            ],
                            onChanged: (v) =>
                                setDialogState(() => selectedPlatform = v!),
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: linkController,
                            label: 'Platform Link (Optional)',
                            hint: 'https://...',
                            icon: Icons.link,
                          ),
                          SizedBox(height: 24),
                          _buildSectionLabel('Study Settings', Icons.settings),
                          SizedBox(height: 12),
                          _buildDropdown(
                            value: selectedType,
                            label: 'Study Type',
                            icon: Icons.location_on,
                            items: ['Online', 'Offline', 'Hybrid'],
                            onChanged: (v) =>
                                setDialogState(() => selectedType = v!),
                          ),
                          if (selectedType != 'Online') ...[
                            SizedBox(height: 16),
                            _buildTextField(
                              controller: locationController,
                              label: 'Location',
                              hint: 'e.g., Library Room 301',
                              icon: Icons.place,
                            ),
                          ],
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: maxController,
                                  label: 'Max Participants',
                                  hint: 'Unlimited',
                                  icon: Icons.people,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: durationController,
                                  label: 'Duration (min)',
                                  hint: '60',
                                  icon: Icons.timer,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          _buildSectionLabel('Schedule', Icons.event),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateTimeButton(
                                  context: context,
                                  label: selectedDate == null
                                      ? 'Select Date'
                                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                  icon: Icons.calendar_today,
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now().add(
                                        Duration(days: 1),
                                      ),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        Duration(days: 365),
                                      ),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: Colors.blue[700]!,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (date != null) {
                                      setDialogState(() => selectedDate = date);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildDateTimeButton(
                                  context: context,
                                  label: selectedTime == null
                                      ? 'Select Time'
                                      : selectedTime!.format(context),
                                  icon: Icons.access_time,
                                  onPressed: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: Colors.blue[700]!,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (time != null) {
                                      setDialogState(() => selectedTime = time);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer Actions
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add_circle_outline),
                          label: Text('Create Session'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty ||
                                descController.text.trim().isEmpty ||
                                subjectController.text.trim().isEmpty ||
                                selectedDate == null ||
                                selectedTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please fill all required fields',
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(context);

                            final scheduledDate = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              selectedTime!.hour,
                              selectedTime!.minute,
                            );

                            try {
                              final result = await StudySessionService.instance
                                  .createStudySession(
                                    title: titleController.text.trim(),
                                    description: descController.text.trim(),
                                    subject: subjectController.text.trim(),
                                    platform: selectedPlatform,
                                    platformLink:
                                        linkController.text.trim().isNotEmpty
                                        ? linkController.text.trim()
                                        : null,
                                    studyType: selectedType,
                                    location:
                                        locationController.text
                                            .trim()
                                            .isNotEmpty
                                        ? locationController.text.trim()
                                        : null,
                                    maxParticipants:
                                        maxController.text.trim().isNotEmpty
                                        ? int.tryParse(
                                            maxController.text.trim(),
                                          )
                                        : null,
                                    scheduledDate: scheduledDate,
                                    duration: int.parse(
                                      durationController.text,
                                    ),
                                  );

                              if (result['success']) {
                                await _loadSessions();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Session created!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to create session: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showParticipantsDialog(StudySession session) async {
    // Fetch participants
    final result = await StudySessionService.instance.getSessionParticipants(
      sessionId: session.id,
      page: 1,
      limit: 50,
    );

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to load participants'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final participants = result['participants'] as List<Participant>;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          constraints: BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Participants',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            session.title,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: participants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No participants yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final participant = participants[index];
                          final isCreator =
                              participant.user.id == session.creator.id;

                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[700],
                                child: Text(
                                  participant.user.email[0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      participant.user.email,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (isCreator)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Creator',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'Joined ${_formatJoinedDate(participant.joinedAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatJoinedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditDialog(StudySession session) {
    final titleController = TextEditingController(text: session.title);
    final descController = TextEditingController(text: session.description);
    final subjectController = TextEditingController(text: session.subject);
    final linkController = TextEditingController(
      text: session.platformLink ?? '',
    );
    final locationController = TextEditingController(
      text: session.location ?? '',
    );
    final maxController = TextEditingController(
      text: session.maxParticipants?.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: session.duration.toString(),
    );

    String selectedPlatform = session.platform;
    String selectedType = session.studyType;
    DateTime? selectedDate = DateTime(
      session.scheduledDate.year,
      session.scheduledDate.month,
      session.scheduledDate.day,
    );
    TimeOfDay? selectedTime = TimeOfDay(
      hour: session.scheduledDate.hour,
      minute: session.scheduledDate.minute,
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width > 600
                ? 600
                : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Edit Study Buddy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Basic Information', Icons.info),
                        SizedBox(height: 12),
                        _buildTextField(
                          controller: titleController,
                          label: 'Title',
                          hint: 'Study session title',
                          icon: Icons.title,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: descController,
                          label: 'Description',
                          hint: 'What will you study?',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: subjectController,
                          label: 'Subject',
                          hint: 'e.g., Mathematics, Physics',
                          icon: Icons.book,
                        ),
                        SizedBox(height: 24),
                        _buildSectionLabel(
                          'Platform & Location',
                          Icons.computer,
                        ),
                        SizedBox(height: 12),
                        _buildDropdown(
                          value: selectedPlatform,
                          label: 'Platform',
                          icon: Icons.video_call,
                          items: [
                            'Zoom',
                            'Google Meet',
                            'Microsoft Teams',
                            'Discord',
                            'Other',
                          ],
                          onChanged: (v) =>
                              setDialogState(() => selectedPlatform = v!),
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: linkController,
                          label: 'Platform Link (Optional)',
                          hint: 'https://...',
                          icon: Icons.link,
                        ),
                        SizedBox(height: 24),
                        _buildSectionLabel('Study Settings', Icons.settings),
                        SizedBox(height: 12),
                        _buildDropdown(
                          value: selectedType,
                          label: 'Study Type',
                          icon: Icons.location_on,
                          items: ['Online', 'Offline', 'Hybrid'],
                          onChanged: (v) =>
                              setDialogState(() => selectedType = v!),
                        ),
                        if (selectedType != 'Online') ...[
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: locationController,
                            label: 'Location',
                            hint: 'e.g., Library Room 301',
                            icon: Icons.place,
                          ),
                        ],
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: maxController,
                                label: 'Max Participants',
                                hint: 'Unlimited',
                                icon: Icons.people,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: durationController,
                                label: 'Duration (min)',
                                hint: '60',
                                icon: Icons.timer,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        _buildSectionLabel('Schedule', Icons.event),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTimeButton(
                                context: context,
                                label: selectedDate != null
                                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                    : 'Select Date',
                                icon: Icons.calendar_today,
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      Duration(days: 365),
                                    ),
                                  );
                                  if (date != null) {
                                    setDialogState(() => selectedDate = date);
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildDateTimeButton(
                                context: context,
                                label: selectedTime != null
                                    ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Select Time',
                                icon: Icons.access_time,
                                onPressed: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        selectedTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setDialogState(() => selectedTime = time);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty ||
                              descController.text.trim().isEmpty ||
                              subjectController.text.trim().isEmpty ||
                              selectedDate == null ||
                              selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please fill all required fields',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);

                          final scheduledDate = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            selectedTime!.hour,
                            selectedTime!.minute,
                          );

                          try {
                            final result = await StudySessionService.instance
                                .updateStudySession(
                                  sessionId: session.id,
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  subject: subjectController.text.trim(),
                                  platform: selectedPlatform,
                                  platformLink:
                                      linkController.text.trim().isNotEmpty
                                      ? linkController.text.trim()
                                      : null,
                                  studyType: selectedType,
                                  location:
                                      locationController.text.trim().isNotEmpty
                                      ? locationController.text.trim()
                                      : null,
                                  maxParticipants:
                                      maxController.text.trim().isNotEmpty
                                      ? int.tryParse(maxController.text.trim())
                                      : null,
                                  scheduledDate: scheduledDate,
                                  duration: int.parse(durationController.text),
                                );

                            if (result['success']) {
                              await _loadSessions();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Session updated!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message']),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update session: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text('Update', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateTimeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, color: Colors.blue[700]),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.blue[300]!, width: 1.5),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text('Study Buddy'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _sessions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _error != null && _sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(_error!),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSessions,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: _sessions.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _sessions.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final session = _sessions[index];
                  return _SessionCard(
                    session: session,
                    onJoin: () => _joinSession(session.id),
                    onLeave: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Leave Session'),
                          content: Text(
                            'Are you sure you want to leave this study buddy?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _leaveSession(session.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: Text('Leave'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDelete: () => _deleteSession(session.id),
                    onEdit: () => _showEditDialog(session),
                    onViewParticipants: () => _showParticipantsDialog(session),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[700],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final StudySession session;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onViewParticipants;

  const _SessionCard({
    required this.session,
    required this.onJoin,
    required this.onLeave,
    required this.onDelete,
    required this.onEdit,
    required this.onViewParticipants,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue;
      case 'Ongoing':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Online':
        return Icons.computer;
      case 'Offline':
        return Icons.location_on;
      case 'Hybrid':
        return Icons.merge_type;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(session.status);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                FutureBuilder<String?>(
                  future: AuthService.instance.getUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox.shrink();

                    final isCreator = snapshot.data == session.creator.id;

                    // Show menu for creator or participant
                    if (isCreator) {
                      return PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Session'),
                                content: Text('Are you sure?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onDelete();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else if (session.hasJoined) {
                      // Show leave option for participants who have joined
                      // Debug: Always show menu for testing
                      print(
                        'Showing leave menu: hasJoined=${session.hasJoined}',
                      );
                      return PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'leave') {
                            onLeave();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'leave',
                            child: Row(
                              children: [
                                Icon(Icons.exit_to_app, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Leave Session'),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Debug: Show for all non-creators temporarily
                      return PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'leave') {
                            onLeave();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'leave',
                            child: Row(
                              children: [
                                Icon(Icons.exit_to_app, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Leave Session'),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.subject,
                style: TextStyle(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              session.description,
              style: TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getTypeIcon(session.studyType),
                  size: 16,
                  color: Colors.grey[700],
                ),
                SizedBox(width: 4),
                Text(session.studyType, style: TextStyle(fontSize: 13)),
                SizedBox(width: 16),
                Icon(Icons.video_call, size: 16, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text(session.platform, style: TextStyle(fontSize: 13)),
              ],
            ),
            if (session.platformLink != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.link, size: 16, color: Colors.blue[700]),
                  SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: session.platformLink!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Link copied to clipboard!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        session.platformLink!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text(session.formattedDate, style: TextStyle(fontSize: 13)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                SizedBox(width: 4),
                Text(
                  '${session.duration} mins',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(width: 16),
                InkWell(
                  onTap: onViewParticipants,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.blue[700]),
                        SizedBox(width: 4),
                        Text(
                          '${session.currentParticipants}${session.maxParticipants != null ? '/${session.maxParticipants}' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (session.isFull) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FULL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
                Spacer(),
                if (session.status == 'Scheduled')
                  if (session.hasJoined)
                    ElevatedButton(
                      onPressed: onLeave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text('Leave', style: TextStyle(fontSize: 13)),
                    )
                  else if (!session.isFull)
                    ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text('Join', style: TextStyle(fontSize: 13)),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
