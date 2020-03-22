# -*- coding: utf-8 -*-
"""
Created on Sat Mar 21 21:43:29 2020

"""

#!pip install sklearn
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import linear_kernel

#input: inputtext
#validated_data: texte aus validierten Quellen in numpy liste
def find_similar_doc(input_data,validated_data):
    #Definiere "unwichtige" Wörter, die nicht gezählt werden
    my_stop_words = ['und', 'auf', 'zu', 'in', 'ist', 'der', 'die', 'das', 'wird','werden', 'hat', 'haben', 'dass', 'wie', 'von', 'oder', 'eine', 'ein', 'einer']
    #Definiere TfidfVectorizer
    tfidf_vectorizer = TfidfVectorizer(stop_words = my_stop_words)
    # Vektorisiere validated Text
    tfidf_validated = tfidf_vectorizer.fit_transform([i['text'] for i in validated_data])
    # Vektorisiere Inputtext
    tfidf_input = tfidf_vectorizer.transform(input_data)
    
    
    #Berechne Ähnlichkeiten zwischen Inputtext und den vertrauenswürdigen Texten über Cosinus
    cosine_similarities = linear_kernel(tfidf_input, tfidf_validated).flatten()
    # Finde Ähnlichkeitswert von besten 2 Dokumenten
    similarity_values = [sorted(cosine_similarities)[-1],sorted(cosine_similarities)[-2]]
    #Finde webstie von am besten passenden Dokument
    similar_website = [validated_data[cosine_similarities.argsort()[-1]]['link'],validated_data[cosine_similarities.argsort()[-2]]['link']]  
    
    #Gibt den text des ähnlichsten Dokuments zurück
    return (similar_website,similarity_values)