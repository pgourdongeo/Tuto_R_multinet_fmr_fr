

#### 1. Importer et créer l'objet ####



### 1.1. Importer un objet multigraphe

library(multinet)

net <- ml_aucs()
layers_ml(net)
net


##### 1.2. Importer des données au format csv et igraph #####


library(igraph)

# import des données (table des liens)
link <- read.csv("data/2018_vallier_data_edgelist.csv", 
                 encoding = "UTF-8")

# suppression des colonnes inutiles
link <- link[,1:3]

#création des 3 objets igraph correspondant à 3 types de liens
coll <- graph_from_data_frame(link[link$Type_fr == "Collaboration",], 
                              directed=FALSE)

## supprimer les liens multiples : de 62 à 31 liens
coll <- simplify(coll, remove.multiple = TRUE) 

cons <- graph_from_data_frame(link[link$Type_fr == "Consortium",], 
                              directed = FALSE) 

# de 20 à 10 liens
cons <- simplify(cons, remove.multiple = TRUE) 

# 17 liens de type orienté
depa <- graph_from_data_frame(link[link$Type_fr == "Dépannage",1:2], 
                              directed = TRUE) 

# création d'un objet multinet vide
clus <- ml_empty()

#ajout des couches igraph
add_igraph_layer_ml(clus, coll, "coll") 
add_igraph_layer_ml(clus, cons, "cons")
add_igraph_layer_ml(clus, depa, "depa")

#propriétés de l'objet créé
clus
layers_ml(clus)


##### 1.3. Appréhender les objets créés #####


# données AUCS
plot(net, vertex.labels = NA)

# données cluster
plot(clus, vertex.labels = NA) 

summary(net)
summary(clus)


##### 1.4. "Aligner" le multigraphe (tous les sommets dans toutes les couches) #####


# pour les données AUCS  : option à l'import

net_aligned <- read_ml(system.file("extdata", "aucs.mpx", package = "multinet"), 
                       "AUCS", aligned = TRUE)
net_aligned # on retrouve bien 61 acteurs * 5 couches = 305 sommets en tout

# pour les données cluster : enregistrement puis import

write_ml(clus, "data/clusAlign", format = "multilayer", 
         sep = ',')


clus_aligned <- read_ml("data/clusAlign", aligned = TRUE)

clus_aligned # 32 acteurs * 3 couches = 96 sommets

# test : différence entre les deux résumés clus et clus_aligned ?

identical(summary(clus), summary(clus_aligned)) 


# spatialiser les sommets dans la même position que pour la 3ème couche
l3 <- layout_multiforce_ml(clus_aligned, w_inter = 1, 
                            w_in = c(0, 0, 1), 
                            gravity = c(0, 0, 1))

# visualisation des trois couches

plot(clus_aligned, layout = l3, grid = c(1, 3), vertex.labels = "")


#### 2. Quelques mesures et analyses  ####

##### 2.1. Créer et étudier les couches individuellemment #####


clus_i <- as.list(clus)
flat <- clus_i$"_flat_"


# créer un object igraph à partir d'une couche

## acteurs disposant d'un compte facebook : n = 32
(fb <- as.igraph(net, "facebook")) 

# version alignée : ensemble des acteurs présents dans le flat
# n = 61 (avec sommets isolés)
fb <- as.igraph(net_aligned, "facebook") 

# même opération mais à partir de la version non-alignée du graphe
fb <- as.igraph(net, "facebook", all.actors = TRUE) 

# retirer deux couches en même temps

f_l_net <- as.igraph(net, 
                     c("facebook","lunch"), # choix des couches
                     merge.actors=TRUE)     # ne conserver qu'un seul sommet par                                             acteur (toutes couches confondues) n = 60




##### 2.2. Centralités, voisinage, distances #####


neighborhood_ml(net,"U54","work")
xneighborhood_ml(net,"U54","work")
relevance_ml(net,"U54","work")
xrelevance_ml(net,"U54","work")


# degrés sur le réseau net

## si la couche n'est pas précisée, le calcul s'effectue sur flat
deg <- degree_ml(net) 
## actors_ml renvoie les noms sous forme de liste :
names(deg) <- unlist(actors_ml(net)) 
## ordonner le vecteur de manière décroissante
top_degrees <- head(deg[order(-deg)])

# degrés sur le réseau clus

degc <- degree_ml(clus_aligned)
names(degc) <- unlist(actors_ml(clus_aligned))
top_degc <- head(degc[order(-degc)])

# tableau des degrés selon les couches

## réseau net

(topdeg <- 
    data.frame(actor = names(top_degrees),
               facebook = degree_ml(net, actors = names(top_degrees), layers = "facebook"),
               leisure = degree_ml(net, actors = names(top_degrees), layers = "leisure"),
               lunch = degree_ml(net, actors = names(top_degrees), layers = "lunch"),
               coauthor = degree_ml(net, actors = names(top_degrees), layers = "coauthor"),
               work = degree_ml(net, actors = names(top_degrees), layers = "work"),
               flat = top_degrees)) 



# réseau clus (avec une couche orientée)

(topdegc <- 
    data.frame(actor = as.character(names(top_degc)),
               coll = degree_ml(clus_aligned, actors = names(top_degc), layers = "coll"),
               cons = degree_ml(clus_aligned, actors = names(top_degc), layers = "cons"),
               depa_in = degree_ml(clus_aligned, actors = names(top_degc), layers = "depa", mode = "in"), #degré entrant
               depa_out = degree_ml(clus_aligned, actors = names(top_degc), layers = "depa", mode = "out"), #degré sortant
               flat = top_degc)) 




# calcul des non-dominated path lengths entre deux sommets 
subset(distance_ml(net,from = "U54",to = "U41", method="multiplex"), 
       lunch == 1 & facebook == 2 | work == 3)



# vérification du fait qu'il n'existe pas de chemin entre U54 et U41 
# comprenant uniquement 2 liens dans la couche facebook
subset(distance_ml(net,from = "U54",to = "U41", method="multiplex"),
       facebook == 2 )


##### 2.3. Comparaison des couches #####


#comparaison distribution degré
layer_comparison_ml(net, method = "jeffrey.degree")



#comparaison distribution degré sur la version alignée du réseau net
layer_comparison_ml(net_aligned, method = "jeffrey.degree")


#même degré dans différentes couches - qq soit les voisins
layer_comparison_ml(clus, method="pearson.degree")


#mêmes sommets dans les différentes couches (0 à 1)
layer_comparison_ml(clus, method="jaccard.actors")


#mêmes liens entre mêmes paires de sommets
layer_comparison_ml(net, method="jaccard.edges")


#mêmes triangles entre mêmes ensemble de 3 sommets
layer_comparison_ml(net, method="jaccard.triangles")


##### 2.4. Détection de communautés #####

#tester les 4 algorithmes
com1 <- glouvain_ml(net)
com2 <- clique_percolation_ml(net)
com3 <- abacus_ml(net, min.actors = 3, min.layers = 3) 
com4 <- infomap_ml(net)

#crée dataframe : sommet, couche, communauté
head(com2, 6) 

#nb communautés et taille selon l'algo choisi
table(com1$cid)
#table(com2$cid)
#table(com3$cid)
table(com4$cid)

#indicateurs
modularity_ml(net, com1, gamma = 1, omega = 1)


#comparaison entre deux partitions 1 - 4
nmi_ml(net, com1, com4)
omega_index_ml(net, com1, com4)

#visualisation
plot(net, vertex.labels.cex=.3, com=com4)


#visualiser le réseau aligné (ici on garde la spatialisation de la première couche)

l4 <- layout_multiforce_ml(net_aligned, w_inter = 1, 
                            w_in = c(1, 0, 0, 0, 0 ), 
                            gravity = c(1, 0, 0, 0, 0 ))


plot(net_aligned, vertex.labels.cex=.3, com=com4, layout = l4)

#### 3. Visualisation ####

# créer une couche valuée à partir de work, facebook et lunch
layers_ml(net)

flatten_ml(net, new.layer = "wfl", layers = c("work", "facebook", "lunch"),
           method = "weighted", force.directed = FALSE, all.actors = FALSE)

layers_ml(net)

attributes_ml(net, target = "edge")

# récupérer les poids pour toutes les couches 
# (sinon cela ne fonctionne pas dans car la fonction plot se base sur le graphe multicouche)

attr_values <- get_values_ml(net, "weight", edges = edges_ml(net))

# représenter la couche

l <- layout_multiforce_ml(net, w_inter = 1, 
                          w_in = c(0, 0, 0, 0, 0, 1), 
                          gravity = c(0, 0, 0, 0, 0, 1))

plot(net,                        #objet mulinet
     layers = "wfl",             #choix des couches
     layout = l,                 #algorithme de placement
     vertex.size = 5,            #taille des sommets
     vertex.color = "orange",    #couleur des sommets
     vertex.labels.size = 0.3,   #taille des labels
     edge.width = unlist(attr_values),  #taille des liens
     edge.col = "grey40",        #couleur des liens
     show.layer.names = FALSE)   #afficher le nom de la couche


