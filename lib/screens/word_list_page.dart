import 'package:flutter/material.dart';
import '../models/word_entry.dart';
import '../services/tts_service.dart';

class WordListPage extends StatefulWidget {
  final List<WordEntry> words;
  const WordListPage({super.key, required this.words});

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word List')),
      body: ListView.separated(
        controller: _controller,
        itemBuilder: (ctx, i) {
          final w = widget.words[i];
          return ListTile(
            title: Text(w.word),
            subtitle: Text('${w.englishMeaning}\n${w.chineseMeaning}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.volume_up, size: 20),
              onPressed: () {
                TtsService.instance.speak(w.word);
              },
            ),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: widget.words.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        child: const Icon(Icons.vertical_align_top),
      ),
    );
  }
}


