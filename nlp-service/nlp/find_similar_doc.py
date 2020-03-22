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
    
    #Definiere TfidfVectorizer
    tfidf_vectorizer = TfidfVectorizer()
    # Vektorisiere Inputtext
    tfidf_input = tfidf_vectorizer.fit_transform(validated_data)
    # Vektorisiere Outputtext
    tfidf_validated = tfidf_vectorizer.transform(input_data)

    
    #Berechne Ähnlichkeiten zwischen Inputtext und den vertrauenswürdigen Texten über Cosinus
    cosine_similarities = linear_kernel(tfidf_input, tfidf_validated).flatten()
    #Finde Index von am besten passenden Dokument
    related_docs_indices = cosine_similarities.argsort()[:-5:-1]
    #Am besten passendes Dokument
    most_similar = validated_data[related_docs_indices[0]]
    
    #Gibt den text des ähnlichsten Dokuments zurück
    return (most_similar)