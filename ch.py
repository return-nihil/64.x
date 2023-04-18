#! /usr/bin/env python3

######################################################################
### CHESS GAMES v.3                                                ###
### Programmed by Ardan Dal Ri,  2022                              ###
######################################################################

'''
TODO:
- Sistemare risultati con messaggio specifico per abbandono/patta
'''


import sys
import math
import keyboard
import argparse
import socket
import chess.pgn
from pythonosc.parsing import osc_types
from pythonosc import udp_client

# GLOBAL:

ipOUT = "127.0.0.1"
sc_portOUT = 57120
p_portOUT = 5007

main_board = chess.Board()


#####################################################################

def obtain_pgn():
    
    print(sys.argv)

    return(sys.argv[1])


def pgn_parser(pgn_file):
    
    with open(pgn_file) as f:
    
        pgn = f.read()

        # Rimuovo header
        first_move_index = pgn.index('1.')
        full_game = pgn[first_move_index:]
    
        # Ottengo lista
        full_notation = full_game.split()
    
        # Rimuovo numero di mosse e risultato
        game = [x for i, x in enumerate(full_notation) if (i+3)%3 !=0]

        results = ['1-0', '0-1', '1/2-1/2']
        moves = [i for i in game if i not in results]


    return(moves)


def print_headers(pgn_file):

    pgn = open(pgn_file)
    game = chess.pgn.read_game(pgn)
    
    white = (game.headers['White']).upper()
    black = (game.headers['Black']).upper()
    date = (game.headers['Date']).upper()
    print()
    print(f'GAME: {white} VS {black}, {date[:4]}')
    print()
    print('Ready to start game!')
    for i in range(3):
        print()



def plot_moves(counter, move):

	count = int(math.floor(counter/2)) + 1

	if (counter % 2) == 0:
		print(f'{count}. {move}')
	else:
		print(f'{count}. ...{move}')
	
	print()
              


def reader(moves):

    counter = 0
    game_duration = len(moves)

    while True:

        keyboard.wait('SPACE')

        last_move = moves[counter]
        coord = str(main_board.parse_san(last_move))
        main_board.push(chess.Move.from_uci(coord))
        plot_moves(counter, last_move)
        print(main_board)

        alphanum = coord_to_alphanum(coord)
        move = joiner(alphanum, coord)

        main(move,ipOUT,sc_portOUT,board,free,captured)
        
        counter += 1
        
        if counter == game_duration:
            print('Game ended!')
            print()
            break
    

def coord_to_alphanum(coord):
    game = chess.pgn.Game()
    x = str(game.from_board(main_board))
    y = x[:(x.rfind(' '))]
    alphanum = y[(y.rfind(' ') + 1):]
    return alphanum


def joiner(alphanum, coord):
    full_move = [str(alphanum), str(coord)]
    print(full_move)
    return full_move 



def initBoard():
	
	board = [ \
	['br2','bn2','bb2','bq1','bk1','bb3','bn3','br3'], \
	['bp8','bp9','bp10','bp11','bp12','bp13','bp14','bp15'], \
	['','','','','','','',''],	\
	['','','','','','','',''],	\
	['','','','','','','',''],	\
	['','','','','','','',''],	\
	['wp0','wp1','wp2','wp3','wp4','wp5','wp6','wp7'], \
	['wr0','wn0','wb0','wq0','wk0','wb1','wn1','wr1']]
	everyone = ['br2','bn2','bb2','bq1','bk1','bb3','bn3','br3',\
	'bp8','bp9','bp10','bp11','bp12','bp13','bp14','bp15',\
	'wp0','wp1','wp2','wp3','wp4','wp5','wp6','wp7',\
	'wr0','wn0','wb0','wq0','wk0','wb1','wn1','wr1']
	free = [j for sub in board for j in sub if j]
	captured = [j for j in everyone if j not in free]
	# output
	return board, free, captured

def indexOnBoard(pos):
	'''
	data una casa restituisce gli indici da usare sulla scacchiera python
	'''
	colonna = ord(pos[0])-97
	riga = 7-int(pos[1])+1 

	return riga,colonna


def pieceName(p):
	'''
	restituisce un nome per il messaggio di output dato un codice pezzo
	'''
	if p[1]=='p':
		return '/pedone'
	elif p[1]=='r': 
		return '/torre'
	elif p[1]=='n': 
		return '/cavallo'
	elif p[1]=='b': 
		return '/alfiere'
	elif p[1]=='q': 
		return '/regina'
	elif p[1]=='k': 
		return '/re'


def main(msg,ipOUT,sc_portOUT,b,f,c):
	'''
	prende il messaggio in arrivo e lo traduce aggiornando la scacchiera
	'''
	# leggi messaggio
	#print("Last move: {}".format(msg))
	# interpreta mosse da messaggio
	chessMove = msg[0]
	coordMove = msg[1]
	# caratteri speciali
	specials = ['O', 'x', '=', '+', '#', '?']
	# inizializza
	msgOUT = []
	# genera messaggio e aggiorna scacchiera
	if not any(c in chessMove[:-1] for c in specials):
		msgS, b = semplice(b,chessMove,coordMove)
		msgOUT.append(msgS)
	if 'O' in chessMove:
		msgA1, msgA2, b = arrocco(b,chessMove,coordMove)
		msgOUT.append(msgA1)
		msgOUT.append(msgA2)
		msgOUT.append('/arrocco')
	if 'x' in chessMove:
		msgP1, msgP2, b, f, c = presa(b,f,c,chessMove,coordMove)
		msgOUT.append(msgP1)
		msgOUT.append(msgP2)
		msgOUT.append('/presa')
	if '=' in chessMove:
		msgU1, msgU2, b, f, c = promozione(b,f,c,chessMove,coordMove)
		msgOUT.append(msgU1)
		msgOUT.append(msgU2)
		msgOUT.append('/promozione')
	if '+' in chessMove:
		msgOUT.append('/scacco')
	if '#' in chessMove:
		msgOUT.append('/matto')
	if '?' in chessMove:
		msgOUT.append('/patta')
	# genera messaggio processing
	pmsg = coordmsg(coordMove)
	# output
	talk2SC(ipOUT,sc_portOUT,msgOUT)
	talk2P(ipOUT,p_portOUT,pmsg)
	print()
	print("SuperCollider message: {}".format(msgOUT))
	print("Processing message: {}".format(pmsg))
	print()


def arrocco(b,chmv,comv):
	'''
	messaggi ed aggiornamento scacchiera in caso di arrocco
	'''
	start = comv[:2]
	stop  = comv[2:]
	if start=='e1':
		b[7][4] = ''
		if stop=='c1':
			msg1 = '/re,7,2'
			msg2 = '/torre,0,7,3,1'
			b[7][2] = 'wk0'
			b[7][0] = ''
			b[7][3] = 'wr0'
		elif stop=='g1':
			msg1 = '/re,7,6'
			msg2 = '/torre,1,7,5,1'
			b[7][6] = 'wk0'
			b[7][7] = ''
			b[7][5] = 'wr1'
	if start=='e8':
		b[0][4] = ''
		if stop=='c8':
			msg1 = '/re,0,2'
			msg2 = '/torre,2,0,3,1'
			b[0][2] = 'bk1'
			b[0][0] = ''
			b[0][3] = 'br2'
		elif stop=='g8':
			msg1 = '/re,0,6'
			msg2 = '/torre,3,0,5,1'
			b[0][6] = 'bk1'
			b[0][7] = ''
			b[0][5] = 'br3'
	# output
	return msg1, msg2, b


def presa(b,f,c,chmv,comv):
	'''
	messaggi ed aggiornamento scacchiera in caso di presa
	'''
	# analizza mossa
	start = comv[:2]
	stop  = comv[2:]
	# interroga casa di partenza
	r1,c1 = indexOnBoard(start)
	p1 = b[r1][c1]
	# interroga casa di arrivo
	r2,c2 = indexOnBoard(stop)
	p2 = b[r2][c2]
	# messaggio 1: prende
	indice1 = int(''.join(filter(str.isdigit, p1)))
	nome1 = pieceName(p1)
	if nome1 == '/re':
		msg1 = '{},{},{}'.format(nome1,r2,c2)
	else:
		msg1 = '{},{},{},{},1'.format(nome1,indice1,r2,c2)
	# messaggio 2: preso
	if not p2: # casa arrivo vuota
		p3 = b[r1][c2]
		nome3 = pieceName(p3)
		indice3 = int(''.join(filter(str.isdigit, p3)))
		# aggiorna scacchiera, presi e liberi
		f.remove(p3)
		c.append(p3)
		b[r1][c2] = ''
		# generate message
		msg2 = '{},{},{},{},0'.format(nome3,indice3,r1,c2) # preso en-passant
	else: # casa arrivo occupata
		nome2 = pieceName(p2)
		indice2 = int(''.join(filter(str.isdigit, p2)))
		# aggiorna presi e liberi
		f.remove(p2)
		c.append(p2)
		# genera messsaggio
		msg2 = '{},{},{},{},0'.format(nome2,indice2,r2,c2) # preso
	# aggiorna scacchiera
	b[r1][c1] = ''
	b[r2][c2] = p1
	# output
	return msg1, msg2, b, f, c


def promozione(b,f,c,chmv,comv):
	'''
	messaggi ed aggiornamento scacchiera in caso di promozione
	'''
	# analizza mossa
	start = comv[:2]
	r1,c1 = indexOnBoard(start)
	stop  = comv[2:]
	r2,c2 = indexOnBoard(stop)
	if 'x' in chmv: # scacchiera aggiornata dalla presa
		p1 = b[r2][c2]
	else:
		p1 = b[r1][c1]
	# interroga casa di arrivo
	# interpreta promozione
	prom = chmv.split('=')[1][0].lower()
	# imposta indice
	freeID = [int(pp[2]) for pp in f if pp[1]==prom]
	freeIDmax = max(freeID) if freeID else 0
	captID = [int(pp[2]) for pp in c if pp[1]==prom]
	captIDmax = max(captID) if captID else 0
	lastID = max(freeIDmax,captIDmax)
	promID = lastID+1
	p2 = p1[0]+prom+str(promID)
	nomePromosso = pieceName(p2)
	# messaggi
	nome1 = pieceName(p1)
	indice1 = int(''.join(filter(str.isdigit, p1)))
	if 'x' in chmv: # scacchiera aggiornata dalla presa
		msg1 = '{},{},{},{},0'.format(nome1,indice1,r2,c2)
	else:
		msg1 = '{},{},{},{},0'.format(nome1,indice1,r1,c1)
		b[r1][c1] = ''
	# aggiorna scacchiera, presi e liberi
	msg2 = '{},{},{},{},1'.format(nomePromosso,promID,r2,c2)
	c.append(p1)
	f.remove(p1)
	f.append(p2)
	b[r2][c2] = p2
	# output
	return msg1, msg2, b, f, c	


def semplice(b,chmv,comv):
	'''
	mossa semplice
	'''
	# analizza mossa
	start = comv[:2]
	stop  = comv[2:]
	# interroga casa di partenza
	r1,c1 = indexOnBoard(start)
	p1 = b[r1][c1]
	# interroga casa di arrivo
	r2,c2 = indexOnBoard(stop)
	p2 = b[r2][c2]
	# indice nome e messaggio
	indice = int(''.join(filter(str.isdigit, p1)))
	nome = pieceName(p1)
	if nome == '/re':
		msg = '{},{},{}'.format(nome,r2,c2)
	else:
		msg = '{},{},{},{},1'.format(nome,indice,r2,c2)
	# aggiorna scacchiera
	b[r1][c1] = ''
	b[r2][c2] = p1
	return msg, b


def coordmsg(coord):
	'''
	costruisce messaggio per Processing a partire da coordinate
	'''
	alphacoord = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
	alpha1 = alphacoord.index(coord[0])
	num1 = coord[1]
	alpha2 = alphacoord.index(coord[2])
	num2 = coord[3]

	pmsg = '{},{},{},{}'.format((8-int(num1)),alpha1,(8-int(num2)),alpha2)

	return pmsg



	
def buildMSG(strmsg):
	'''
	costruisci un messaggio OSC da una lista di stringhe. 
	Questa funzione si bassa sul OscMessageBuilder dello script osc_message_builder.py della libreria python-osc
	INPUT = un messaggio che contenga solo stringhe ed interi
	OUTPUT = un oggetto OSC (bytes)
	
	'''
	# inizializza
	dgramSTR = strmsg.strip().split(',')
	# find types, we only have strings or integers
	arg_types = []
	for arg in dgramSTR:
		if arg.isdigit():
			arg_types.append('i')
		else:
			arg_types.append('s')
	# build message
	dgram = b'' # inizializza
	dgram += osc_types.write_string(dgramSTR[0]) # write first item (always a string)
	if len(dgramSTR) == 1:
		return dgram
	else:
		arg_types_blob = "".join([argty for argty in arg_types])
		dgram += osc_types.write_string(',' + arg_types_blob[1:])
		for ii,arg_type in enumerate(arg_types[1:]): # starting from second element
			if arg_type=='s': # string
				dgram += osc_types.write_string(dgramSTR[ii+1])
			elif arg_type=='i': # integer
				dgram += osc_types.write_int(int(dgramSTR[ii+1]))
		# output
		#print(dgram)
		return dgram



def talk2SC(ip,port,mymove):
	'''
	invia messaggio via client su IP/porta
	'''
	sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP
	for msgOUT in mymove:
		mvOUT = buildMSG(msgOUT)
		sock.sendto(mvOUT, (ip, port))


def talk2P(ip,port,msg):
	'''
	invia messaggio via client su IP/porta
	'''
	sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP
	'''print(f'msg: {msg}')
	for x in msg:
		trigger = buildMSG(x)
		print(f'x {x}')
		print(f'trigger {trigger}')
		sock.sendto(bytes(trigger), (ip, port))'''
	#sock.sendto(msg, (ip, port))
	client = udp_client.SimpleUDPClient(ip, port)
	client.send_message("/msg", msg)


###########################################################################


if __name__ == '__main__':

    board, free, captured = initBoard()
    game = obtain_pgn()
    print_headers(game)
    moves = pgn_parser(game)
    reader(moves)

