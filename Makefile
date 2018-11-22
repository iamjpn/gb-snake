
object: snake.asm tiles.asm
	rgbasm -o snake.o snake.asm
	rgbasm -o tiles.o tiles.asm

rom: object 
	rgblink -o snake.gb -n snake.sym snake.o tiles.o
	rgbfix -v -p 0 snake.gb

