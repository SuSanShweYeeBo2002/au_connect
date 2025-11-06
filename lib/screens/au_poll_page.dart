import 'package:flutter/material.dart';
import '../services/poll_service.dart';
import '../services/auth_service.dart';

class AuPollPage extends StatefulWidget {
  @override
  _AuPollPageState createState() => _AuPollPageState();
}

class _AuPollPageState extends State<AuPollPage> {
  List<Poll> _polls = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPolls();
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
        _loadMorePolls();
      }
    }
  }

  Future<void> _loadPolls() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await PollService.getPolls(page: 1);
      setState(() {
        _polls = response.polls;
        _hasMore = response.pagination.hasNext;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePolls() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await PollService.getPolls(page: _currentPage + 1);
      setState(() {
        _polls.addAll(response.polls);
        _hasMore = response.pagination.hasNext;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load more polls')));
    }
  }

  Future<void> _votePoll(String pollId, int optionIndex) async {
    try {
      final updatedPoll = await PollService.votePoll(
        pollId: pollId,
        optionIndex: optionIndex,
      );

      setState(() {
        final index = _polls.indexWhere((p) => p.id == pollId);
        if (index != -1) {
          _polls[index] = updatedPoll;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vote recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to vote: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePoll(String pollId) async {
    try {
      final success = await PollService.deletePoll(pollId);
      if (success) {
        setState(() {
          _polls.removeWhere((p) => p.id == pollId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Poll deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete poll: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreatePollDialog() {
    final questionController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    DateTime? selectedExpiry;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create New Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  decoration: InputDecoration(
                    labelText: 'Question',
                    hintText: 'What do you want to ask?',
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...List.generate(
                  optionControllers.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: optionControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              hintText: 'Enter option',
                            ),
                          ),
                        ),
                        if (optionControllers.length > 2)
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                optionControllers.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                if (optionControllers.length < 6)
                  TextButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Option'),
                    onPressed: () {
                      setDialogState(() {
                        optionControllers.add(TextEditingController());
                      });
                    },
                  ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Expiry: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedExpiry = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text(
                        selectedExpiry == null
                            ? 'No expiry'
                            : '${selectedExpiry!.day}/${selectedExpiry!.month}/${selectedExpiry!.year}',
                      ),
                    ),
                    if (selectedExpiry != null)
                      IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setDialogState(() {
                            selectedExpiry = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final question = questionController.text.trim();
                final options = optionControllers
                    .map((c) => c.text.trim())
                    .where((text) => text.isNotEmpty)
                    .toList();

                if (question.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a question')),
                  );
                  return;
                }

                if (options.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter at least 2 options')),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  await PollService.createPoll(
                    question: question,
                    options: options,
                    expiresAt: selectedExpiry,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Poll created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadPolls();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create poll: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text('AU Poll'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _polls.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _error != null && _polls.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(_error!),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadPolls, child: Text('Retry')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPolls,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: _polls.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _polls.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final poll = _polls[index];
                  return _PollCard(
                    poll: poll,
                    onVote: (optionIndex) => _votePoll(poll.id, optionIndex),
                    onDelete: () => _deletePoll(poll.id),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePollDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[700],
        tooltip: 'Create Poll',
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;
  final Function(int) onVote;
  final VoidCallback onDelete;

  const _PollCard({
    required this.poll,
    required this.onVote,
    required this.onDelete,
  });

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.hasVoted;
    final isExpired = poll.isExpired;

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
                CircleAvatar(
                  backgroundColor: Colors.blue[300],
                  child: Text(
                    poll.authorName.isNotEmpty
                        ? poll.authorName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poll.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getTimeAgo(poll.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                FutureBuilder<String?>(
                  future: AuthService.instance.getUserId(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == poll.authorId) {
                      return PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Poll'),
                                content: Text(
                                  'Are you sure you want to delete this poll?',
                                ),
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
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              poll.question,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            ...List.generate(poll.options.length, (index) {
              final option = poll.options[index];
              final percentage = poll.getOptionPercentage(index);
              final isUserVote = hasVoted && poll.userVotedIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: (!hasVoted && !isExpired) ? () => onVote(index) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUserVote ? Colors.blue[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUserVote ? Colors.blue : Colors.grey[300]!,
                        width: isUserVote ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (hasVoted || isExpired)
                          FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  option.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isUserVote
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasVoted || isExpired)
                                Text(
                                  '${percentage.toStringAsFixed(1)}% (${option.votes})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${poll.totalVotes} ${poll.totalVotes == 1 ? 'vote' : 'votes'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (poll.expiresAt != null)
                  Text(
                    isExpired
                        ? 'Expired'
                        : 'Expires: ${poll.expiresAt!.day}/${poll.expiresAt!.month}/${poll.expiresAt!.year}',
                    style: TextStyle(
                      color: isExpired ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
