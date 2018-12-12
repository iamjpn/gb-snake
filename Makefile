
object: snake.asm tiles.asm
	rgbasm -o snake.o snake.asm
	rgbasm -o snake_tiles.o snake_tiles.asm

rom: object 
	rgblink -o snake.gb -n snake.sym snake.o snake_tiles.o
	rgbfix -v -m 3 -p 0 -r 2 snake.gb

