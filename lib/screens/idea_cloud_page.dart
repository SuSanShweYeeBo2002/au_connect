import 'package:flutter/material.dart';
import '../services/note_service.dart';

class IdeaCloudPage extends StatefulWidget {
  @override
  _IdeaCloudPageState createState() => _IdeaCloudPageState();
}

class _IdeaCloudPageState extends State<IdeaCloudPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Note> _notes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreNotes();
    }
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await NoteService.getNotes(page: 1);
      setState(() {
        _notes = response.notes;
        _currentPage = response.pagination.currentPage;
        _hasMore = response.pagination.hasNext;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      _showErrorSnackBar(_errorMessage!);
    }
  }

  Future<void> _loadMoreNotes() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await NoteService.getNotes(page: _currentPage + 1);
      setState(() {
        _notes.addAll(response.notes);
        _currentPage = response.pagination.currentPage;
        _hasMore = response.pagination.hasNext;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _addNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      _showErrorSnackBar('Please enter both title and content');
      return;
    }

    if (title.length > 200) {
      _showErrorSnackBar('Title cannot exceed 200 characters');
      return;
    }

    if (content.length > 5000) {
      _showErrorSnackBar('Content cannot exceed 5000 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newNote = await NoteService.createNote(
        title: title,
        content: content,
      );

      setState(() {
        _notes.insert(0, newNote);
        _titleController.clear();
        _contentController.clear();
        _isLoading = false;
      });

      Navigator.of(context).pop();
      _showSuccessSnackBar('Note created successfully');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _updateNote(Note note) async {
    _titleController.text = note.title;
    _contentController.text = note.content;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.blue[700], size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Edit Note',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        style: TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(fontSize: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          hintText: 'Enter note title...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        maxLength: 200,
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _contentController,
                        style: TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Content',
                          labelStyle: TextStyle(fontSize: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          hintText: 'Enter note content...',
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        maxLines: 8,
                        minLines: 5,
                        maxLength: 5000,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _titleController.clear();
                      _contentController.clear();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _performUpdate(note),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performUpdate(Note note) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      _showErrorSnackBar('Please enter both title and content');
      return;
    }

    try {
      final updatedNote = await NoteService.updateNote(
        noteId: note.id,
        title: title,
        content: content,
      );

      setState(() {
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = updatedNote;
        }
      });

      _titleController.clear();
      _contentController.clear();
      Navigator.of(context).pop();
      _showSuccessSnackBar('Note updated successfully');
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await NoteService.deleteNote(note.id);
      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
      });
      _showSuccessSnackBar('Note deleted successfully');
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showAddNoteDialog() {
    _titleController.clear();
    _contentController.clear();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.blue[700],
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Add New Note',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        style: TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(fontSize: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          hintText: 'Enter note title...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        maxLength: 200,
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _contentController,
                        style: TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Content',
                          labelStyle: TextStyle(fontSize: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          hintText: 'Enter note content...',
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        maxLines: 8,
                        minLines: 5,
                        maxLength: 5000,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDetails(Note note) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: Colors.blue[700], size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          note.content,
                          style: TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Created: ${_formatDate(note.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            if (note.updatedAt != note.createdAt)
                              SizedBox(height: 6),
                            if (note.updatedAt != note.createdAt)
                              Row(
                                children: [
                                  Icon(
                                    Icons.update,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Updated: ${_formatDate(note.updatedAt)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text('Close', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateNote(note);
                    },
                    icon: Icon(Icons.edit),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Idea Cloud'),
        backgroundColor: Colors.blue[300],
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: _isLoading && _notes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null && _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadNotes, child: Text('Retry')),
                ],
              ),
            )
          : _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notes yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first note',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: _notes.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _notes.length) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final note = _notes[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shadowColor: Colors.blue.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () => _showNoteDetails(note),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.blue[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    note.title,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PopupMenuButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Colors.blue[700],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Edit',
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Future.delayed(
                                          Duration(milliseconds: 100),
                                          () => _updateNote(note),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Delete',
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Future.delayed(
                                          Duration(milliseconds: 100),
                                          () => _deleteNote(note),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 14),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                note.content,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.blue[600],
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _formatDate(note.createdAt),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: Icon(Icons.add, size: 28),
        label: Text(
          'Add Note',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 6,
        tooltip: 'Add Note',
      ),
    );
  }
}
