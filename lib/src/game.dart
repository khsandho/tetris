part of tetris;

class Game {
  CanvasElement board;
  Element gameScore;
  Block currentBlock;

  static int width = 16;
  static int height = 28;
  static int cellSize = 21;

  static int linesCleared;
  static int bestScore;
  static CanvasRenderingContext2D ctx;

  static List<List<int>> boardState;
  static List<int> rowState;

  Game() {
    linesCleared = 0;
    bestScore = 0;
    gameScore = Element.div()..id = "score";

    rowState = List<int>.filled(height, 0);
    boardState = List<int>(width)
        .map(
          (_) => List<int>.filled(height, 0),
    )
        .toList();


    fs.Firestore store = firestore();
    fs.CollectionReference ref = store.collection('scores');

    ref.onSnapshot.listen((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        bestScore = int.parse(doc.get('tetris'));
      });
    });
  }

  Block getRandomPiece() {
    int randomInt = Random().nextInt(5);
    switch (randomInt) {
      case 0:
        return IBlock(width);
      case 1:
        return OBlock(width);
      case 2:
        return JBlock(width);
      case 3:
        return TBlock(width);
      case 4:
        return SBlock(width);
    }
    return Block();
  }

  void clearRows() async {
    for (int idx = 0; idx < rowState.length; idx++) {
      int row = rowState[idx];

      if(linesCleared > bestScore) {
        fs.Firestore store = firestore();
        fs.CollectionReference ref = store.collection('scores');

        ref.onSnapshot.listen((querySnapshot) async {

          var change = querySnapshot.docChanges()[0];


          print('$change');


          var docSnapshot = change.doc;

          var value = docSnapshot.data();

          value['tetris'] = linesCleared.toString();

          try {
            await ref.doc(docSnapshot.id).update(data: value);
            bestScore = linesCleared;
          } catch (e) {
            print('Error while updating item, $e');
          }
        });
      }
    }
  }

  //[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  //[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,7,4,10]
  //[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,7,4]

  //      0        1        2        3
  // [[0,0,0,0][0,0,0,0][0,0,0,0][0,0,0,0]]
  // [[0,0,0,1][0,0,1,1][0,1,1,1][0,0,1,1]]
  // [[0,0,0,0][0,0,0,1][0,0,1,1][0,0,0,1]]

  bool validMove() {
    for (Tile tile in currentBlock.tiles) {
      if (tile.x >= width ||
          tile.x < 0 ||
          tile.y >= height ||
          tile.y < 0 ||
          boardState[tile.x][tile.y] == 1) {
        return false;
      }
    }
    return true;
  }

  bool pieceMoving(String s) {
    bool pieceIsMoving = true;

    ctx.fillStyle = '#161719';

    currentBlock.tiles.forEach((Tile tile) {
      ctx.fillRect(
        tile.x * cellSize,
        tile.y * cellSize,
        cellSize,
        cellSize,
      );
    });

    if (s == 'rotate') {
      currentBlock.rotateRight();
    } else {
      currentBlock.move(s);
    }

    if (!(pieceIsMoving = validMove())) {
      if (s == 'rotate') currentBlock.rotateLeft();
      if (s == 'left') currentBlock.move('right');
      if (s == 'right') currentBlock.move('left');
      if (s == 'down') currentBlock.move('up');
      if (s == 'up') currentBlock.move('down');
    }



    ctx.fillStyle = currentBlock.color;

    currentBlock.tiles.forEach((tile) {
      ctx.fillRect(
        tile.x * cellSize,
        tile.y * cellSize,
        cellSize,
        cellSize,
      );
    });

    for (var x = 0; x <= board.width; x += cellSize) {
      ctx.moveTo(0.5 + x + cellSize, 0);
      ctx.lineTo(0.5 + x + cellSize, board.height + cellSize);
    }

    for (var x = 0; x <= board.height; x += cellSize) {
      ctx.moveTo(0, 0.5 + x + cellSize);
      ctx.lineTo(board.width + cellSize, 0.5 + x + cellSize);
    }

    ctx.strokeStyle = "#232526";
    ctx.stroke();

    return pieceIsMoving;
  }

  void updateGame(Timer timer) {
    gameScore.setInnerHtml("<div><div>Score</div><div>${linesCleared}</div></div><div><div>Best</div> <div>${bestScore}</div></div>");

    if (!pieceMoving('down')) {
      currentBlock.tiles.forEach((t) {
        boardState[t.x][t.y] = 1;
        rowState[t.y]++;
      });
      clearRows();
      currentBlock = getRandomPiece();
      if (!pieceMoving('down')) {
        timer.cancel();
      }
    }


  }

  void initializeCanvas() {
    board = Element.html('<canvas/>');
    board.width = width * cellSize;
    board.height = height * cellSize;
    ctx = board.context2D;

    ctx.fillStyle = '#161719';

    ctx.fillRect(0, 0, board.width, board.height);


  }

  void handleKeyboard(Timer timer) {
    document.onKeyDown.listen((event) {
      if (timer.isActive) {
        if (event.keyCode == 37) pieceMoving('left');

        if (event.keyCode == 38) pieceMoving('rotate');

        if (event.keyCode == 39) pieceMoving('right');

        if (event.keyCode == 40) pieceMoving('down');

        if (event.keyCode == 32) while (pieceMoving('down')) {}
      }
    });
  }

  void start() {
    initializeCanvas();

    Element entryPoint = querySelector('#output');

    entryPoint.nodes.add(board);
    entryPoint.nodes.add(gameScore);

    Timer timer = Timer.periodic(
      Duration(milliseconds: 250),
      updateGame,
    );

    currentBlock = getRandomPiece();
    handleKeyboard(timer);
  }
}
